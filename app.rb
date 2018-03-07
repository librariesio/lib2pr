require 'bundler'
require 'json'
Bundler.require

require 'dependabot/file_fetchers'
require 'dependabot/pull_request_creator'
require 'dependabot/file_parsers'
require 'dependabot/update_checkers'
require 'dependabot/metadata_finders'
require 'dependabot/file_updaters'

class Lib2Pr < Sinatra::Base
  use Rack::Deflater

  configure do
    set :logging, true
    set :dump_errors, false
    set :raise_errors, true
    set :show_exceptions, false
  end

  before do
    request.body.rewind
    @data = JSON.parse request.body.read
  end

  post '/webhook' do
    content_type :json

    create_pr(@data['repository'], @data['platform'], @data['name'])

    status 200
    body ''
  end

  def create_pr(repository, platform, name)
    return if ENV['SKIP_PRERELEASE'] && prerelease?(platform, version)
    return if satisfied_by_requirements?(requiremnts, version, platform)

    send_prs(repo, platform, name, 'github')
  end

  def platform_to_package_manager(platform)
    {
      'rubygems' => 'bundler',
      'npm' => 'npm_and_yarn',
      'maven' => 'maven',
      'pypi' => 'pip',
      'packagist' => 'composer',
      'hex' => 'hex'
    }[platform.downcase]
  end

  def send_prs(repo_name, platform, name, host)

    package_manager = platform_to_package_manager(platform)

    github_client = Octokit::Client.new(access_token: ENV['GITHUB_TOKEN'])
    credentials = [{"host" => "github.com", 'password' =>  ENV['GITHUB_TOKEN']}]
    repo = github_client.repo(repo_name)
    branch = github_client.branch(repo_name, repo.default_branch)
    base_commit = branch.commit.sha

    fetcher_class = Dependabot::FileFetchers.for_package_manager(package_manager)
    file_updater_class = Dependabot::FileUpdaters.for_package_manager(package_manager)
    update_checker_class = Dependabot::UpdateCheckers.for_package_manager(package_manager)
    parser_class = Dependabot::FileParsers.for_package_manager(package_manager)
    metadata_finder_class = Dependabot::MetadataFinders.for_package_manager(package_manager)

    filenames = github_client.contents(repo_name).map(&:name)

    unless fetcher_class.required_files_in?(filenames)
      raise fetcher_class.required_files_message
    end

    fetcher = fetcher_class.new(source: {repo: repo_name, host: host}, credentials: credentials)

    files = fetcher.files

    parser = parser_class.new(dependency_files: files, repo: repo)

    dependencies = parser.parse

    dependencies_needing_update = []

    dependencies.select{|d| d.name == name }.each do |dependency|

      update_checker = update_checker_class.new(
        dependency: dependency,
        dependency_files: files,
        credentials: credentials
      )

      dependency = update_checker.updated_dependencies(requirements_to_unlock: :own)

      unless dependency.length.zero?

        metadata_finder = metadata_finder_class.new(
          dependency: dependency,
          credentials: credentials
        )

        dependencies_needing_update << dependency
      end
    end

    dependencies_needing_update.flatten!

    dependencies_needing_update.each do |dependency|

      file_updater = file_updater_class.new(
        dependencies: [dependency],
        dependency_files: files,
        credentials: credentials
      )

      creator = Dependabot::PullRequestCreator.new(repo: repo_name,
            base_commit: base_commit,
            dependencies: [dependency],
            files: file_updater.updated_dependency_files,
            github_client: github_client
          )

      creator.create
    end
  end

  def satisfied_by_requirements?(requiremnts, version, platform = nil)
    return false if requiremnts.nil? || requiremnts.empty?
    requiremnts.none? do |requirement|
      SemanticRange.gtr(version, requirement, false, platform)
    end
  rescue
    false
  end

  def prerelease?(platform, version)
    parsed_version = SemanticRange.parse(version) rescue nil
    return true if parsed_version && parsed_version.prerelease.length > 0
    if platform.downcase == 'rubygems'
      !!(version =~ /[a-zA-Z]/)
    else
      false
    end
  end
end
