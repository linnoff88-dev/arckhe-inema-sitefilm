ï»¿# ARCKHÉ-sitefilm ê¢â¬â Sinal

<div align="center">
  <img src="capa/logo.svg" alt="Arckhé AI" height="48" />
  <p><strong>Arckhé AI</strong></p>
</div>


Site scroll-film do [ARCKHÉ AI](https://ARCKHÉ AI): a pêÂ¡gina inteira êÂ© um plano-sequêÂªncia que roda conforme o visitante rola, e se dissolve no conteêÂºdo do portal ao final. ConstruêÂ­do com a skill [scroll-film-studio](https://github.com/linnoff88-dev/fable5skill) (fable5skill).

**Jornada:** RuêÂ­do (dados dispersos) ê¢â â ConvergêÂªncia ê¢â â NêÂºcleo ê¢â â Rede ê¢â â Portal ê¢â¬â literalizando o slogan "acesso centralizado aos seus cursos e plataformas".

## As 5 versêÂµes (menu no topo de todas)

| VersêÂ£o | URL | Lane / Engine | EstêÂ©tica |
|---|---|---|---|
| **Filme I** | [/](https://linnoff88-dev.github.io/arckhe-/) | Lane C ê¢â¬â Agnes AI (US$0), keyframes interpolados | partêÂ­culas ciano/violeta, orgêÂ¢nico |
| **Filme II** | [/index2.html](https://linnoff88-dev.github.io/arckhe-/index2.html) | Lane C (mesma footage) ê¢â¬â *Director's Cut* | abertura com o filme dentro das letras SINAL, voo pela tipografia, dots de capêÂ­tulo clicêÂ¡veis, timeline de scrub |
| **Filme III** | [/index3.html](https://linnoff88-dev.github.io/arckhe-/index3.html) | Lane B ê¢â¬â Kie.ai Seedance v1 Lite (720p) | neon-geomêÂ©trico, têÂºnel roxo/verde |
| **Code I** | [/lane-a.html](https://linnoff88-dev.github.io/arckhe-/lane-a.html) | Lane A ê¢â¬â GSAP + Lenis puro | vertical, ciano, partêÂ­culas em canvas |
| **Code II** | [/lane-a2.html](https://linnoff88-dev.github.io/arckhe-/lane-a2.html) | Lane A v2 ê¢â¬â corrida horizontal pinada | êÂ¢mbar, nêÂºmeros outline, containerAnimation |

## Como cada filme foi feito

- **Filme I/II (Agnes, US$0):** 6 keyframes encadeados via img2img derivado (`agnes-image-2.1-flash`), 5 clipes interpolando pares Aê¢â âB (`agnes-video-v2.0`, `mode:keyframes`), gate de SSIM em cada emenda. 141 frames de scrub em `frames/`.
- **Filme III (Kie.ai, ~112 crêÂ©ditos):** cadeia Lane B verdadeira ê¢â¬â cada clipe parte do **êÂºltimo frame real do anterior** (`bytedance/v1-lite-image-to-video`). 301 frames em `frames-kie/`. Runner: `kie-chain.sh` (upload ê¢â â createTask ê¢â â poll ê¢â â download ê¢â â extraêÂ§êÂ£o de frame ê¢â â SSIM). `fal-chain.sh` êÂ© o runner equivalente para fal.ai.
- **Engine de scrub (Filmes):** canvas + ImageBitmap sliding window (decode fora da main thread), playhead com lerp, header com luminêÂ¢ncia adaptativa, dissolve na cor da emenda do êÂºltimo frame.
- **Code I/II:** zero assets ê¢â¬â sêÂ³ GSAP/ScrollTrigger/Lenis de CDN; jank max ~17-19ms.

## VerificaêÂ§êÂ£o

Todas as pêÂ¡ginas implementam o contrato de dev da skill: `?jump=<scrollY>` pousa prêÂ©-rolado e `window.__ready` sinaliza pêÂ¡gina pronta. `verify.js` (puppeteer-core + Chromium) tira screenshots em qualquer ponto do scroll e roda o teste de jank (p95/max de deltas de rAF, nunca FPS mêÂ©dio).

```bash
python3 -m http.server 8931          # servir local
node verify.js jank http://localhost:8931/index.html
node verify.js shot "http://localhost:8931/index3.html?jump=4600" out.png 1440 900
```

## Estrutura

```
index.html        Filme I  (Lane C, Agnes)         frames/       141 frames Agnes
index2.html       Filme II (Director's Cut)         frames-kie/   301 frames Seedance
index3.html       Filme III (Lane B, Kie Seedance)  kie-chain.sh  runner Kie.ai
lane-a.html       Code I  (GSAP vertical)           fal-chain.sh  runner fal.ai
lane-a2.html      Code II (GSAP horizontal êÂ¢mbar)   verify.js     harness puppeteer
```

IntermediêÂ¡rios de build (clipes brutos, keyframes) ficam fora do repo (`.gitignore`) ê¢â¬â sêÂ³ o runtime êÂ© publicado. Nenhuma API key no repositêÂ³rio.

---

<div align="center">
  <img src="capa/logo.svg" alt="Arckhé AI" height="32" />
  <p><strong>Arckhé AI</strong></p>
</div>