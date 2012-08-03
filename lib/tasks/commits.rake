require 'repository'

namespace :commits do
  desc "Fetch new commits (if any)"
  task :update => :environment do
    repos = Repository::SvnRepos.new(Takeout::Conf.repos_url)
    repos.fetch_commits.each do |commit|
      p commit.save!
    end
  end

  task :reget => :environment do
    repos = Repository::SvnRepos.new(Takeout::Conf.repos_url)
    Commit.order("key DESC").each do |commit|
      Commit.transaction do
        newc = repos.fetch_commit(commit.key).attributes
        %w(log diff commited_at).each do |k|
          commit.send("#{k}=", newc[k])
        end
        p commit.save!
      end
    end
  end
end
