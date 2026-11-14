// Loja (loja.html): vitrine, compra pelo Mercado Pago e acompanhamento do pedido.
// O catálogo e os preços vêm de /api/loja (servidor/api/server.js); aqui ficam só
// os textos de vitrine e as imagens de cada item.
(function () {
  // mantos: texto de vitrine (as cores de cada variação vêm de content/skins/*.tres)
  const MANTOS = {
    casa_oram: { cores: ["#1f6b6a", "#2a5a8a", "#d8d4c8"], pt: "As cores da Casa Oram, que guarda a cinza em jarros de vidro e chama isso de fé.", en: "House Oram's colours. They keep the ash in glass jars and call it faith." },
    casa_kael: { cores: ["#2a2420", "#4a2a1a", "#c8bca0"], pt: "Kael nunca perdeu uma batalha. Perdeu todas as outras coisas.", en: "Kael never lost a battle. It lost everything else." },
    cinza_sagrada: { cores: ["#b8b0a4", "#8a8078"], pt: "Coberto da cinza que as três Casas disputam. Nenhuma delas reconhece você.", en: "Covered in the ash the three Houses fight over. None of them claims you." },
    ouro_imperador: { cores: ["#c8a040", "#1a1612"], pt: "Tecido para um imperador que não queria ver. Os olhos fechados vêm junto.", en: "Woven for an emperor who refused to see. The closed eyes come with it." },
    fulgurante: { cores: ["#3a7ad8", "#5a3a9a"], pt: "Vidro que lembra de ter sido raio. Brilha mais quando você está com medo.", en: "Glass that remembers being lightning. It glows brighter when you're afraid." },
    ultima_pagina: { cores: ["#e8dcc0", "#1e1c24"], pt: "Escrita em todas as línguas, com uma frase só. Você sabe qual.", en: "Written in every language, a single sentence. You know which one." },
    abissal: { cores: ["#14284a", "#0a0a14"], pt: "Do fundo da Catedral Submersa, onde a luz é coisa que os peixes fazem.", en: "From the depths of the Sunken Cathedral, where light is something fish make." },
    coral_morto: { cores: ["#e89a8a", "#e8e4dc"], pt: "Já foi vivo, colorido e cheio de gente pequena. Agora é só bonito.", en: "It was alive once, colourful and full of tiny folk. Now it is only beautiful." },
    voz_do_fundo: { cores: ["#101814", "#3a3a1a"], pt: "Ninguém que ouviu a voz voltou para contar o que ela dizia.", en: "No one who heard the voice came back to say what it said." },
    constelacao: { cores: ["#1a2050", "#4a2060"], pt: "Bordado com o mapa do céu de antes. Algumas estrelas já não estão lá.", en: "Embroidered with the map of the old sky. Some of those stars are gone." },
    aurora: { cores: ["#2aa878", "#9ad8ff"], pt: "A luz que dança no céu dos Salões quando o inverno esquece de ser cruel.", en: "The light that dances over the Halls when winter forgets to be cruel." },
    sol_negro: { cores: ["#141010", "#3a0a0e"], pt: "O sol que nasce em Carcosa. Não ilumina; só mostra onde está o resto.", en: "The sun that rises over Carcosa. It gives no light; it only shows where the rest is." },
    brasa_eterna: { cores: ["#c83a14", "#2a2422"], nome: ["Brasa Eterna", "Eternal Ember"] },
    inverno_longo: { cores: ["#d8ecf8", "#4a8ab8"], nome: ["Inverno Longo", "Long Winter"] },
  };
  const KIND_TEXT = {
    lamina: ["Muda a cor do arco do golpe, do clarão e solta faíscas ao atacar.", "Changes the colour of your swing arc and flash, with sparks on every attack."],
    rastro: ["Silhuetas coloridas na rolagem e no mergulho, e partículas ao correr.", "Coloured afterimages when you roll and dive, and particles as you run."],
    filtro: ["Muda as cores da tela inteira. Liga e desliga quando quiser.", "Recolours the whole screen. Turn it on and off whenever you like."],
  };
  const SECTIONS = [
    { id: "destaques", pt: "Destaques", en: "Featured", tipos: ["destaque"],
      sub: ["Os conjuntos combinam manto, lâmina, rastro e filtro. O manto deles só existe ali.", "Sets match a cloak, blade, trail and filter. Their cloak exists nowhere else."] },
    { id: "pacotes", pt: "Pacotes", en: "Packs", tipos: ["pacote"], sub: ["Mais barato que comprar cada um.", "Cheaper than buying each one."] },
    { id: "mantos", pt: "Mantos", en: "Cloaks", tipos: ["manto"], sub: ["A aparência do herói. Cada manto vem com as variações de cor.", "The hero's look. Every cloak comes with its colour variants."] },
    { id: "laminas", pt: "Lâminas", en: "Blades", tipos: ["lamina"], sub: KIND_TEXT.lamina },
    { id: "rastros", pt: "Rastros", en: "Trails", tipos: ["rastro"], sub: KIND_TEXT.rastro },
    { id: "filtros", pt: "Filtros", en: "Filters", tipos: ["filtro"], sub: KIND_TEXT.filtro },
  ];
  const PACK_TEXT = {
    "pacote:casas": ["Três estandartes da guerra pela cinza.", "Three banners from the war over the ash."],
    "pacote:profecia": ["O que o livro profético previu, em tecido.", "What the book of prophecy foretold, in cloth."],
    "pacote:abismo": ["O que mora no fundo da Catedral Submersa.", "What lives at the bottom of the Sunken Cathedral."],
    "pacote:ceu": ["O céu de antes dos deuses sumirem.", "The sky from before the gods vanished."],
    "pacote:laminas": ["As seis cores de golpe.", "All six swing colours."],
    "pacote:rastros": ["Os seis rastros: brasa, geada, pétalas, vazio, ouro e estrelas.", "All six trails: ember, frost, petals, void, gold and stars."],
    "pacote:filtros": ["Os seis filtros de tela.", "All six screen filters."],
    "conjunto:brasa": ["Manto Brasa Eterna + Corte de Brasa + Rastro de Brasas + Filtro Brasa.", "Eternal Ember cloak + Ember Cut + Ember Trail + Ember Filter."],
    "conjunto:geada": ["Manto Inverno Longo + Corte de Geada + Rastro de Geada + Filtro Inverno.", "Long Winter cloak + Frost Cut + Frost Trail + Winter Filter."],
    "pacote:completo": ["Todos os mantos (até os dos conjuntos), lâminas, rastros e filtros.", "Every cloak (set ones included), blade, trail and filter."],
  };
  const ERRORS = {
    loja_fechada: ["A loja abre em breve: o pagamento ainda está sendo configurado.", "The store opens soon: payments are still being set up."],
    ja_tem: ["Você já tem tudo o que vem nesse item.", "You already own everything in this item."],
    sem_personagem: ["Crie seu personagem antes de comprar.", "Create your character before buying."],
    muitas_tentativas: ["Muitas tentativas. Espere um pouco.", "Too many tries. Wait a bit."],
    rede: ["Sem conexão. Tente de novo.", "No connection. Try again."],
  };
  const STATUS = {
    aprovado: ["ok", "Pagamento aprovado! Abra o jogo de novo e escolha em OS MANTOS.", "Payment approved! Reopen the game and pick it at THE CLOAKS."],
    pendente: ["", "Esperando o pagamento. Pix costuma cair em segundos; esta página atualiza sozinha.", "Waiting for payment. Pix usually lands in seconds; this page updates by itself."],
    recusado: ["err", "O pagamento foi recusado. Nada foi cobrado; tente outro meio.", "The payment was declined. Nothing was charged; try another method."],
    estornado: ["err", "Esse pedido foi estornado.", "This order was refunded."],
  };

  let shop = null, buying = null, names = {}, single = {};
  const pedido = new URLSearchParams(location.search).get("pedido");
  const L = () => M.lang;
  const money = c => (c / 100).toLocaleString(L() === "en" ? "en-US" : "pt-BR", { style: "currency", currency: "BRL" });
  const kindOf = id => id.startsWith("lamina_") ? "lamina" : id.startsWith("rastro_") ? "rastro" : id.startsWith("filtro_") ? "filtro" : "manto";
  const nameOf = id => (names[id] || (MANTOS[id] && MANTOS[id].nome) || [id, id])[L() === "en" ? 1 : 0];
  const pic = (id, cls) => {
    const k = kindOf(id);
    const src = k === "manto" ? "img/skins/" + id + ".png" : "img/loja/" + id + ".png";
    const e = M.el("img", { src, alt: "", loading: "lazy", title: nameOf(id) });
    if (cls) e.className = cls;
    if (k === "manto") { e.width = 58; e.height = 80; }
    return e;
  };

  function notice(kind, text) {
    const n = document.getElementById("notice");
    n.className = "msg notice" + (kind ? " " + kind : "");
    n.textContent = text;
    n.hidden = !text;
  }

  // a imagem do topo de cada card, conforme o que vem dentro
  function visual(item) {
    const ids = item.conteudo;
    const mantos = ids.filter(i => kindOf(i) === "manto");
    const fx = ids.filter(i => kindOf(i) !== "manto");
    if (item.tipo === "conjunto") {
      return M.el("div", { class: "set" }, M.el("div", { class: "stage" }, ...mantos.map(i => pic(i))),
        M.el("div", { class: "thumbs" }, ...fx.map(i => pic(i))));
    }
    if (ids.length === 1 && fx.length === 1) return M.el("div", { class: "shot" }, pic(ids[0]));
    if (mantos.length === 0) return M.el("div", { class: "mosaic" }, ...fx.slice(0, 6).map(i => pic(i)));
    const show = mantos.length > 6 ? mantos.filter((_, i) => i % Math.ceil(mantos.length / 6) === 0).slice(0, 6) : mantos;
    return M.el("div", { class: "stage" + (show.length > 3 ? " six" : "") }, ...show.map(i => pic(i)));
  }

  function buyArea(item) {
    const area = M.el("div", { class: "buy" });
    const price = M.el("div", { class: "price" }, M.el("b", { text: money(item.centavos) }));
    const full = item.conteudo.reduce((a, id) => a + (single[id] || 0), 0);
    if (item.conteudo.length > 1 && full > item.centavos) {
      price.append(M.el("s", { text: money(full) }), M.el("em", { text: M.t("ECONOMIZE ", "SAVE ") + Math.round(100 - item.centavos * 100 / full) + "%" }));
    }
    area.append(price);
    const has = new Set(shop.tem);
    const missing = item.conteudo.filter(id => !has.has(id)).length;
    if (!missing) {
      area.append(M.el("span", { class: "owned", text: M.t("✓ VOCÊ TEM", "✓ OWNED") }));
      return area;
    }
    let btn;
    if (!shop.logado) {
      btn = M.el("a", { class: "btn", href: "/conta.html?volta=/loja.html", text: M.t("Entrar", "Sign in") });
    } else {
      btn = M.el("button", { class: "btn", type: "button", text: shop.aberta ? M.t("Comprar", "Buy") : M.t("Em breve", "Soon") });
      if (buying === item.id) { btn.disabled = true; btn.textContent = "…"; }
      btn.addEventListener("click", () => buy(item));
      btn.setAttribute("aria-label", M.t("Comprar ", "Buy ") + item[L()] + " · " + money(item.centavos));
    }
    area.append(btn);
    return area;
  }

  function card(item) {
    const has = new Set(shop.tem);
    const big = item.conteudo.length > 1;
    const all = item.conteudo.every(id => has.has(id));
    const box = M.el("article", { class: (big ? "pack" : "skin") + (item.id === "pacote:completo" ? " best" : "") + (all ? " has" : "") });
    if (item.id === "pacote:completo") box.append(M.el("span", { class: "ribbon", text: M.t("MELHOR PREÇO", "BEST VALUE") }));
    else if (item.tipo === "conjunto") box.append(M.el("span", { class: "ribbon", text: M.t("CONJUNTO", "SET") }));
    if (big) box.append(M.el("span", { class: "count", text: item.conteudo.length + M.t(" ITENS", " ITEMS") }));
    box.append(visual(item));
    const body = M.el("div", { class: "body" }, M.el("h3", { text: item[L()] }));
    if (big) {
      const t = PACK_TEXT[item.id];
      if (t) body.append(M.el("p", { text: t[L() === "en" ? 1 : 0] }));
      if (item.conteudo.length <= 6 && item.tipo !== "conjunto") body.append(M.el("p", { class: "names", text: item.conteudo.map(nameOf).join(" · ") }));
    } else {
      const id = item.conteudo[0], k = kindOf(id);
      if (k === "manto" && MANTOS[id]) {
        body.append(M.el("p", { class: "lore", text: MANTOS[id][L()] || "" }));
        body.append(M.el("div", { class: "swatches", title: M.t("Variações de cor inclusas", "Colour variants included") },
          ...MANTOS[id].cores.map(c => { const e = M.el("i"); e.style.background = c; return e; }),
          M.el("span", { text: MANTOS[id].cores.length + M.t(" CORES", " COLOURS") })));
      }
    }
    box.append(body, buyArea(item));
    return box;
  }

  function render() {
    if (!shop) return;
    const who = document.getElementById("who");
    who.replaceChildren();
    if (shop.logado && shop.nome) who.append(M.t("Comprando para ", "Buying for "), M.el("b", { text: shop.nome }));
    else if (shop.logado) who.append(M.el("a", { href: "/conta.html?volta=/loja.html", text: M.t("Crie seu personagem para comprar", "Create your character to buy") }));
    else who.append(M.el("a", { href: "/conta.html?volta=/loja.html", text: M.t("Entre na conta para comprar", "Sign in to buy") }));

    const tabs = document.getElementById("tabs");
    tabs.replaceChildren(...SECTIONS.map(sec => M.el("a", { href: "#" + sec.id, text: sec[L()] })));
    const groups = SECTIONS.map(sec => {
      const items = shop.itens.filter(i => sec.tipos.includes(i.tipo === "conjunto" || i.id === "pacote:completo" ? "destaque" : i.tipo));
      const wrap = M.el("section", { class: "sec", id: sec.id, "aria-labelledby": sec.id + "-t" },
        M.el("h2", { id: sec.id + "-t", text: sec[L()] }), M.el("p", { text: sec.sub[L() === "en" ? 1 : 0] }));
      const grid = M.el("div", { class: items.some(i => i.conteudo.length > 1) ? "packs" : "skins" }, ...items.map(card));
      wrap.append(grid);
      return wrap;
    });
    document.getElementById("sections").replaceChildren(...groups);
  }

  async function buy(item) {
    if (buying) return;
    if (!shop.aberta) { notice("", M.t(ERRORS.loja_fechada[0], ERRORS.loja_fechada[1])); return; }
    if (!shop.nome) { location.href = "/conta.html?volta=/loja.html"; return; }
    buying = item.id; render();
    const r = await M.api("POST", "/api/loja/comprar", { item: item.id });
    if (r.ok && r.url) { location.href = r.url; return; }
    buying = null; render();
    if (r.status === 401) { location.href = "/conta.html?volta=/loja.html"; return; }
    const e = ERRORS[r.erro] || ["Não deu para abrir o pagamento. Tente de novo.", "Couldn't open the payment. Try again."];
    notice("err", M.t(e[0], e[1]));
  }

  async function load() {
    const r = await M.api("GET", "/api/loja");
    if (!r.ok) { notice("err", M.t("A loja não carregou. Recarregue a página.", "The store didn't load. Reload the page.")); return; }
    shop = r;
    names = {}; single = {};
    for (const i of shop.itens) if (i.conteudo.length === 1) { names[i.conteudo[0]] = [i.pt, i.en]; single[i.conteudo[0]] = i.centavos; }
    if (!shop.aberta && !pedido) notice("", M.t(ERRORS.loja_fechada[0], ERRORS.loja_fechada[1]));
    render();
  }

  // voltou do Mercado Pago: mostra a situação e pergunta de novo enquanto estiver pendente
  async function watchOrder(tries = 0) {
    const r = await M.api("GET", "/api/loja/pedido?id=" + encodeURIComponent(pedido));
    if (!r.ok) return;
    const st = STATUS[r.situacao] || STATUS.pendente;
    notice(st[0], M.t("Pedido #", "Order #") + r.pedido + " · " + M.t(st[1], st[2]));
    if (r.situacao === "aprovado") await load();
    else if (r.situacao === "pendente" && tries < 40) setTimeout(() => watchOrder(tries + 1), tries < 10 ? 3000 : 8000);
  }

  M.onLang(render);
  document.addEventListener("DOMContentLoaded", () => {
    load().then(() => { if (pedido && /^\d+$/.test(pedido)) watchOrder(); });
  });
}());
