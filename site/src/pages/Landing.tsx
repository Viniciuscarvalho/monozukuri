import { motion } from "framer-motion";
import { Terminal, FileText, ShieldAlert, Cpu } from "lucide-react";

const base = import.meta.env.BASE_URL;

export default function Landing() {
  const fadeUp = {
    hidden: { opacity: 0, y: 20 },
    visible: { opacity: 1, y: 0, transition: { duration: 0.6, ease: "easeOut" } }
  };

  const stagger = {
    hidden: { opacity: 0 },
    visible: {
      opacity: 1,
      transition: {
        staggerChildren: 0.1
      }
    }
  };

  return (
    <div className="min-h-screen bg-[#111110] text-[#EBEBEA] font-sans selection:bg-[#534AB7] selection:text-white">
      {/* Navbar */}
      <nav className="fixed top-0 left-0 right-0 z-50 bg-[#111110]/80 backdrop-blur-md border-b border-white/5">
        <div className="max-w-5xl mx-auto px-6 h-16 flex items-center justify-between">
          <div className="font-mono text-sm tracking-tight font-bold">ものづくり monozukuri</div>
          <div className="flex gap-6 text-sm font-mono text-white/50">
            <a href="https://github.com/Viniciuscarvalho/monozukuri" target="_blank" rel="noreferrer" className="hover:text-white transition-colors" data-testid="link-github-nav">GitHub</a>
            <a href="https://github.com/Viniciuscarvalho/monozukuri/issues" target="_blank" rel="noreferrer" className="hover:text-white transition-colors" data-testid="link-issues-nav">Issues</a>
          </div>
        </div>
      </nav>

      <main className="pt-32 pb-24">
        {/* 1. Hero */}
        <section className="max-w-5xl mx-auto px-6 pt-20 pb-32">
          <motion.div initial="hidden" animate="visible" variants={stagger} className="max-w-3xl">
            <motion.div variants={fadeUp} className="inline-flex items-center gap-2 px-3 py-1 mb-6 border border-white/10 bg-white/5 text-xs font-mono text-white/70">
              <span className="w-2 h-2 rounded-full bg-[#0F6E56]"></span>
              Open Source v1.0.0
            </motion.div>
            <motion.h1 variants={fadeUp} className="text-5xl md:text-7xl font-semibold tracking-tight mb-8 leading-tight">
              Orchestrate parallel <br/><span className="text-white/40">AI agent pipelines.</span>
            </motion.h1>
            <motion.p variants={fadeUp} className="text-lg md:text-xl text-white/60 mb-10 max-w-2xl leading-relaxed">
              For developers who ship faster with AI. Queue eight features on a Friday night, review PRs by morning. Precise, disciplined, and unapologetically engineered.
            </motion.p>
            
            <motion.div variants={fadeUp} className="flex flex-col sm:flex-row gap-4 items-start sm:items-center">
              <div className="flex items-center bg-black border border-white/10 rounded-sm overflow-hidden">
                <div className="px-4 py-3 border-r border-white/10 text-white/30 font-mono text-sm">
                  <Terminal size={16} />
                </div>
                <code className="px-6 py-3 font-mono text-sm text-[#E1F5EE]">
                  brew install viniciuscarvalho/tap/monozukuri
                </code>
              </div>
              <a 
                href="https://github.com/Viniciuscarvalho/monozukuri" 
                target="_blank"
                rel="noreferrer"
                data-testid="link-github-hero"
                className="px-6 py-3 bg-white text-black font-medium hover:bg-white/90 transition-colors text-sm rounded-sm"
              >
                View Source on GitHub
              </a>
            </motion.div>
          </motion.div>
        </section>

        {/* 2. The Problem */}
        <section className="max-w-5xl mx-auto px-6 py-24 border-t border-white/5">
          <motion.div initial="hidden" whileInView="visible" viewport={{ once: true, margin: "-100px" }} variants={stagger}>
            <motion.div variants={fadeUp} className="mb-16">
              <h2 className="text-3xl font-semibold tracking-tight mb-4">The human bottleneck</h2>
              <p className="text-white/60 max-w-2xl text-lg">
                Sequential chat limits your throughput to your own attention span. You are the loop. Monozukuri moves the loop to git worktrees, generating branches and pull requests in parallel while you sleep.
              </p>
            </motion.div>
            
            <motion.div variants={fadeUp} className="bg-black/50 border border-white/5 rounded-lg p-2 md:p-8">
              <img src={`${base}assets/before-after.svg`} alt="Sequential vs Parallel" className="w-full h-auto opacity-90" />
            </motion.div>
          </motion.div>
        </section>

        {/* 3. The Pipeline */}
        <section className="max-w-5xl mx-auto px-6 py-24 border-t border-white/5">
          <motion.div initial="hidden" whileInView="visible" viewport={{ once: true, margin: "-100px" }} variants={stagger}>
            <motion.div variants={fadeUp} className="mb-16">
              <h2 className="text-3xl font-semibold tracking-tight mb-4">The six-phase pipeline</h2>
              <p className="text-white/60 max-w-2xl text-lg">
                We split the problem into distinct, verifiable phases. Plan phases use Opus for reasoning. Execute phases use Sonnet for speed and precision. Every phase leaves a named artifact.
              </p>
            </motion.div>
            
            <motion.div variants={fadeUp} className="bg-black/50 border border-white/5 rounded-lg p-2 md:p-8">
              <img src={`${base}assets/six-phase-pipeline.svg`} alt="Six-phase pipeline" className="w-full h-auto opacity-90" />
            </motion.div>
          </motion.div>
        </section>

        {/* 4. Overnight Example */}
        <section className="max-w-5xl mx-auto px-6 py-24 border-t border-white/5">
          <motion.div initial="hidden" whileInView="visible" viewport={{ once: true, margin: "-100px" }} variants={stagger}>
            <motion.div variants={fadeUp} className="mb-16">
              <h2 className="text-3xl font-semibold tracking-tight mb-4">Real run, real results</h2>
              <p className="text-white/60 max-w-2xl text-lg">
                Three features dispatched at 11 PM. Three PRs waiting for review at 5 AM. Total API cost: $14.62.
              </p>
            </motion.div>
            
            <motion.div variants={fadeUp} className="bg-black/50 border border-white/5 rounded-lg p-2 md:p-8">
              <img src={`${base}assets/overnight-timeline.svg`} alt="Overnight timeline" className="w-full h-auto opacity-90" />
            </motion.div>
          </motion.div>
        </section>

        {/* 5. Learning Store */}
        <section className="max-w-5xl mx-auto px-6 py-24 border-t border-white/5">
          <motion.div initial="hidden" whileInView="visible" viewport={{ once: true, margin: "-100px" }} variants={stagger}>
            <motion.div variants={fadeUp} className="mb-16">
              <h2 className="text-3xl font-semibold tracking-tight mb-4">Memory that compounds</h2>
              <p className="text-white/60 max-w-2xl text-lg">
                Errors aren't wasted. A failed build creates a learning that primes the next phase. Project patterns emerge and bubble up to your global heuristic profile.
              </p>
            </motion.div>
            
            <motion.div variants={fadeUp} className="bg-black/50 border border-white/5 rounded-lg p-2 md:p-8">
              <img src={`${base}assets/three-tier-learning.svg`} alt="Three-tier learning store" className="w-full h-auto opacity-90" />
            </motion.div>
          </motion.div>
        </section>

        {/* 6. Features */}
        <section className="max-w-5xl mx-auto px-6 py-24 border-t border-white/5">
          <motion.div initial="hidden" whileInView="visible" viewport={{ once: true, margin: "-100px" }} variants={stagger}>
            <motion.div variants={fadeUp} className="mb-16">
              <h2 className="text-3xl font-semibold tracking-tight mb-4">Built for control</h2>
              <p className="text-white/60 max-w-2xl text-lg">
                Autonomy doesn't mean giving up the wheel. Monozukuri is designed to be stopped, inspected, and resumed at any boundary.
              </p>
            </motion.div>
            
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              <motion.div variants={fadeUp} className="p-6 border border-white/10 bg-white/[0.02]">
                <Cpu className="w-6 h-6 text-[#534AB7] mb-4" />
                <h3 className="font-mono text-sm font-bold text-white mb-2">Autonomy Levels</h3>
                <p className="text-sm text-white/50">Run in supervised mode (Ink TUI), checkpoint mode (pause at phase boundaries), or full_auto for overnight runs.</p>
              </motion.div>
              <motion.div variants={fadeUp} className="p-6 border border-white/10 bg-white/[0.02]">
                <FileText className="w-6 h-6 text-[#0F6E56] mb-4" />
                <h3 className="font-mono text-sm font-bold text-white mb-2">Backlog Adapters</h3>
                <p className="text-sm text-white/50">Ingest tasks from local markdown files, GitHub Issues, or Linear. Standardized into the pipeline seamlessly.</p>
              </motion.div>
              <motion.div variants={fadeUp} className="p-6 border border-white/10 bg-white/[0.02]">
                <ShieldAlert className="w-6 h-6 text-[#BA7517] mb-4" />
                <h3 className="font-mono text-sm font-bold text-white mb-2">Budget & Breakers</h3>
                <p className="text-sm text-white/50">Set strict token budgets per run. Phase-level circuit breakers stop loops before they burn cash.</p>
              </motion.div>
            </div>
          </motion.div>
        </section>

        {/* 7. Install / CTA */}
        <section className="max-w-5xl mx-auto px-6 py-32 border-t border-white/5 text-center">
          <motion.div initial="hidden" whileInView="visible" viewport={{ once: true }} variants={stagger} className="flex flex-col items-center">
            <motion.h2 variants={fadeUp} className="text-4xl font-semibold tracking-tight mb-8">Start building.</motion.h2>
            
            <motion.div variants={fadeUp} className="inline-flex items-center bg-black border border-white/10 rounded-sm overflow-hidden mb-12">
              <div className="px-4 py-3 border-r border-white/10 text-white/30 font-mono text-sm">
                <Terminal size={16} />
              </div>
              <code className="px-6 py-3 font-mono text-sm text-[#E1F5EE]">
                brew install viniciuscarvalho/tap/monozukuri
              </code>
            </motion.div>

            <motion.div variants={fadeUp} className="flex gap-6 justify-center text-sm font-mono text-white/50 mb-12">
              <a href="https://github.com/Viniciuscarvalho/monozukuri" target="_blank" rel="noreferrer" className="hover:text-white transition-colors underline decoration-white/20 underline-offset-4">GitHub Repository</a>
              <a href="https://github.com/Viniciuscarvalho/monozukuri/issues" target="_blank" rel="noreferrer" className="hover:text-white transition-colors underline decoration-white/20 underline-offset-4">Open Issues</a>
            </motion.div>

            <motion.p variants={fadeUp} className="text-white/40 italic">
              "If you find it useful, write about it."
            </motion.p>
          </motion.div>
        </section>
      </main>

      {/* 8. Footer */}
      <footer className="border-t border-white/5 py-12 text-center text-xs font-mono text-white/30">
        <div className="max-w-5xl mx-auto px-6 flex flex-col md:flex-row justify-between items-center gap-4">
          <div>ものづくり monozukuri</div>
          <div className="flex gap-6">
            <a href="https://github.com/Viniciuscarvalho/monozukuri" target="_blank" rel="noreferrer" className="hover:text-white transition-colors">GitHub</a>
            <a href="https://twitter.com/viniciuscarvalho" target="_blank" rel="noreferrer" className="hover:text-white transition-colors">@viniciuscarvalho</a>
            <span>MIT License</span>
          </div>
        </div>
      </footer>
    </div>
  );
}
