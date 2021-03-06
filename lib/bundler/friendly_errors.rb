# encoding: utf-8
require "cgi"
require "bundler/vendored_thor"

module Bundler
  def self.with_friendly_errors
    yield
  rescue Bundler::Dsl::DSLError => e
    Bundler.ui.error e.message
    exit e.status_code
  rescue Bundler::BundlerError => e
    Bundler.ui.error e.message, :wrap => true
    Bundler.ui.trace e
    exit e.status_code
  rescue Thor::AmbiguousTaskError => e
    Bundler.ui.error e.message
    exit 15
  rescue Thor::UndefinedTaskError => e
    Bundler.ui.error e.message
    exit 15
  rescue Thor::Error => e
    Bundler.ui.error e.message
    exit 1
  rescue LoadError => e
    raise e unless e.message =~ /cannot load such file -- openssl|openssl.so|libcrypto.so/
    Bundler.ui.error "\nCould not load OpenSSL."
    Bundler.ui.warn <<-WARN, :wrap => true
      You must recompile Ruby with OpenSSL support or change the sources in your \
      Gemfile from 'https' to 'http'. Instructions for compiling with OpenSSL \
      using RVM are available at http://rvm.io/packages/openssl.
    WARN
    Bundler.ui.trace e
    exit 1
  rescue Interrupt => e
    Bundler.ui.error "\nQuitting..."
    Bundler.ui.trace e
    exit 1
  rescue SystemExit => e
    exit e.status
  rescue Exception => e
    request_issue_report_for(e)
    exit 1
  end

  def self.request_issue_report_for(e)
    Bundler.ui.info <<-EOS.gsub(/^ {6}/, '')
      #{'――― ERROR REPORT TEMPLATE ―――――――――――――――――――――――――――――――――――――――――――――――――――――――'}
      - What did you do?
      - What did you expect to happen?
      - What happened instead?

      Error details

          #{e.class}: #{e.message}
          #{e.backtrace.join("\n          ")}

      #{Bundler::Env.new.report(:print_gemfile => false).gsub(/\n/, "\n      ").strip}
      #{'――― TEMPLATE END ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――'}

    EOS

    Bundler.ui.error "Unfortunately, an unexpected error occurred, and Bundler cannot continue."

    Bundler.ui.warn <<-EOS.gsub(/^ {6}/, '')

      First, try this link to see if there are any existing issue reports for this error:
      #{issues_url(e)}

      If there aren't any reports for this error yet, please create copy and paste the report template above into a new issue. Don't forget to anonymize any private data! The new issue form is located at:
      https://github.com/bundler/bundler/issues/new
    EOS
  end

  def self.issues_url(exception)
    'https://github.com/bundler/bundler/search?q=' \
    "#{CGI.escape(exception.message.lines.first.chomp)}&type=Issues"
  end

end
