// O que as páginas de conta, ranking, perfil, privacidade e painel têm em comum:
// idioma (o mesmo da landing), chamadas à API e o seletor PT/EN do topo.
(function () {
  let lang = "pt";
  try { lang = localStorage.getItem("moksha-lang") || ((navigator.language || "").toLowerCase().startsWith("pt") ? "pt" : "en"); } catch (e) {}
  const listeners = [];

  const M = {
    get lang() { return lang; },
    // M.t("texto em português", "english text")
    t(pt, en) { return lang === "en" ? en : pt; },
    setLang(l) {
      lang = l === "en" ? "en" : "pt";
      try { localStorage.setItem("moksha-lang", lang); } catch (e) {}
      document.documentElement.lang = lang === "pt" ? "pt-BR" : "en";
      document.querySelectorAll("[data-set-lang]").forEach(b => b.setAttribute("aria-pressed", String(b.dataset.setLang === lang)));
      document.querySelectorAll("[data-pt]").forEach(el => { el.textContent = lang === "en" ? el.dataset.en : el.dataset.pt; });
      listeners.forEach(fn => fn(lang));
    },
    onLang(fn) { listeners.push(fn); },
    async api(method, path, body) {
      let r;
      try {
        r = await fetch(path, { method, credentials: "same-origin",
          headers: body ? { "Content-Type": "application/json" } : {}, body: body ? JSON.stringify(body) : undefined });
      } catch (e) { return { ok: false, erro: "rede" }; }
      let data = {};
      try { data = await r.json(); } catch (e) {}
      return { ok: r.ok, status: r.status, ...data };
    },
    el(tag, props = {}, ...kids) {
      const e = document.createElement(tag);
      for (const [k, v] of Object.entries(props)) {
        if (k === "class") e.className = v; else if (k === "text") e.textContent = v; else e.setAttribute(k, v);
      }
      kids.forEach(k => e.append(k));
      return e;
    },
    clock(sec) {
      sec = Math.round(Number(sec) || 0);
      const h = Math.floor(sec / 3600), m = Math.floor(sec % 3600 / 60), s = sec % 60;
      return (h ? h + ":" + String(m).padStart(2, "0") : m) + ":" + String(s).padStart(2, "0");
    },
    // as mesmas chaves que o jogo usa (Run.today / Run.this_week), na data de Brasília
    todayKey(offsetDays = 0) {
      const d = new Date(Date.now() + offsetDays * 86400000);
      const p = new Intl.DateTimeFormat("en-CA", { timeZone: "America/Sao_Paulo", year: "numeric", month: "2-digit", day: "2-digit" }).format(d);
      return p;
    },
    weekKey() {
      const [y, m, d] = M.todayKey().split("-").map(Number);
      const unix = Date.UTC(y, m - 1, d) / 1000;
      return "S" + Math.floor((unix + 3 * 86400) / (7 * 86400));
    },
  };
  window.M = M;
  document.addEventListener("DOMContentLoaded", () => {
    document.querySelectorAll("[data-set-lang]").forEach(b => b.addEventListener("click", () => M.setLang(b.dataset.setLang)));
    M.setLang(lang);
  });
}());
