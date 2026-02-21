# Homebrew formula for mac-dev-audit
# To install from a tap:
#   brew tap YOUR_USERNAME/mac-dev-audit
#   brew install mac-dev-audit

class MacDevAudit < Formula
  desc "Professional macOS developer environment diagnostics CLI tool"
  homepage "https://github.com/YOUR_USERNAME/mac-dev-audit"
  url "https://github.com/YOUR_USERNAME/mac-dev-audit/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "REPLACE_WITH_ACTUAL_SHA256_AFTER_RELEASE"
  license "MIT"
  head "https://github.com/YOUR_USERNAME/mac-dev-audit.git", branch: "main"

  depends_on :macos

  def install
    # Install main executable
    bin.install "mac-dev-audit"

    # Install library files
    (libexec/"lib").install Dir["lib/*.sh"]

    # Install modules
    (libexec/"modules").install Dir["modules/*.sh"]

    # Install patterns
    (libexec/"patterns").install Dir["patterns/*"]

    # Install config
    (libexec/"config").install Dir["config/*"]

    # Rewrite the script to find libraries in libexec
    inreplace bin/"mac-dev-audit" do |s|
      s.gsub! 'SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"',
              "SCRIPT_DIR=\"#{libexec}\""
    end
  end

  test do
    assert_match "mac-dev-audit version", shell_output("#{bin}/mac-dev-audit --version")
    assert_match "macOS Dev Audit Tool", shell_output("#{bin}/mac-dev-audit --help")
  end
end
