# typed: false
# frozen_string_literal: true

class Monozukuri < Formula
  desc "Monozukuri (ものづくり) — autonomous feature delivery, the art of making things"
  homepage "https://github.com/Viniciuscarvalho/monozukuri"
  url "https://github.com/Viniciuscarvalho/monozukuri/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "PLACEHOLDER"
  version "1.0.0"
  license "MIT"
  head "https://github.com/Viniciuscarvalho/monozukuri.git", branch: "main"

  depends_on "jq"
  depends_on "node"

  def install
    libexec_dir = libexec/"monozukuri"

    libexec_dir.install "scripts/orchestrate.sh"
    libexec_dir.install Dir["scripts/lib"]
    libexec_dir.install Dir["scripts/adapters"]

    # Loose helpers
    %w[
      agent-discovery.sh route-tasks.sh worktree-manager.sh environment-discovery.sh
      feedback-collector.sh guardrails.sh audit_commands.sh project_inventory.sh
      validate_diff_scope.sh validate_spec_references.sh verify_build.sh
      sanitize-backlog.js parse-config.js status-writer.js
    ].each do |f|
      libexec_dir.install "scripts/#{f}" if File.exist?("scripts/#{f}")
    end

    libexec_dir.install Dir["templates"]

    libexec_dir.glob("**/*.sh").each { |f| f.chmod 0755 }

    (bin/"monozukuri").write <<~EOS
      #!/bin/bash
      set -euo pipefail
      export MONOZUKURI_HOME="#{libexec}/monozukuri"
      exec bash "#{libexec}/monozukuri/orchestrate.sh" "$@"
    EOS
  end

  def caveats
    <<~EOS
      Monozukuri (ものづくり) — the art of making things.

      Get started in any git project:
        monozukuri init
        monozukuri run --dry-run
        monozukuri run

      By default, Monozukuri invokes the feature-marker Claude Code skill.
      Change the skill in .monozukuri/config.yaml:
        skill:
          command: feature-marker   # or any other Claude Code skill

      Dependencies installed automatically:
        jq   — JSON processing
        node — JavaScript runtime (adapters and config parser)
    EOS
  end

  test do
    assert_match "Usage:", shell_output("#{bin}/monozukuri --help")

    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        system "git", "init"
        system "#{bin}/monozukuri", "init"
        assert_predicate Pathname(dir)/".monozukuri/config.yaml", :exist?
        assert_predicate Pathname(dir)/".env.example", :exist?
      end
    end
  end
end
