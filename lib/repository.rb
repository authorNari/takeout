class Repository
  MAX_FETCH = 20

  def initialize(url)
    @url = url
  end

  def command(_cmd)
    cmd = "#{_cmd} 2>&1"
    Rails.logger.info "- executing command: #{cmd.inspect}"
    ret = `#{cmd}`
    Rails.logger.debug "  result: " + ret.inspect
    ret
  end

  class SvnRepos < Repository
    def fetch_commits(&block)
      next_rev = if (last_commit = Commit.order("created_at DESC").first)
                   last_commit.key[/\d+/].to_i + 1
                 else
                   1
                 end

      revs = (next_rev..get_latest_rev).to_a.last(MAX_FETCH)
      revs.each do |rev|
        yield fetch_commit("r#{rev}")
      end
    end

    def fetch_commit(key)
      rev = key[/\d+/].to_i
      diff = get_svn_diff(rev)
      log = get_svn_log(rev)
      message = log.lines.to_a[3..-2].join.strip
      author = log.lines.to_a[1].split(/\|/)[1].strip
      commited_at = DateTime.parse(log.lines.to_a[1].split(/\|/)[2])

      return Commit.new(key: "r#{rev}",
                        log: message,
                        diff: diff,
                        author: author,
                        commited_at: commited_at)
    end

    private

    def get_latest_rev
      rev_s = command("svn info #{@url}")[/Revision: (\d+)/, 1]
      if rev_s
        rev_s.to_i
      else
        raise "Failed to get latest revision from svn info"
      end
    end

    def get_svn_log(rev)
      command("svn log -r #{rev} #{@url}")
    end

    def get_svn_diff(rev)
      if rev == 1
        "[Sorry, Takeout cannot show diff of r1]"
      else
        command("svn diff -r #{rev-1}:#{rev} #{@url}")
      end
    end
  end

  class GitRepos < Repository
    def fetch_commits(last_key)
      "git fetch master"
    end
  end
end


