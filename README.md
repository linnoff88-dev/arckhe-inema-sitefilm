# inema-sitefilm â€” Sinal

<div align="center">
  <img src="capa/logo.svg" alt="Arckhé AI" height="48" />
  <p><strong>Arckhé AI</strong></p>
</div>


Site scroll-film do [INEMA.CLUB](https://inema.club): a pÃ¡gina inteira Ã© um plano-sequÃªncia que roda conforme o visitante rola, e se dissolve no conteÃºdo do portal ao final. ConstruÃ­do com a skill [scroll-film-studio](https://github.com/inematds/fable5skill) (fable5skill).

**Jornada:** RuÃ­do (dados dispersos) â†’ ConvergÃªncia â†’ NÃºcleo â†’ Rede â†’ Portal â€” literalizando o slogan "acesso centralizado aos seus cursos e plataformas".

## As 5 versÃµes (menu no topo de todas)

| VersÃ£o | URL | Lane / Engine | EstÃ©tica |
|---|---|---|---|
| **Filme I** | [/](https://inematds.github.io/inema-sitefilm/) | Lane C â€” Agnes AI (US$0), keyframes interpolados | partÃ­culas ciano/violeta, orgÃ¢nico |
| **Filme II** | [/index2.html](https://inematds.github.io/inema-sitefilm/index2.html) | Lane C (mesma footage) â€” *Director's Cut* | abertura com o filme dentro das letras SINAL, voo pela tipografia, dots de capÃ­tulo clicÃ¡veis, timeline de scrub |
| **Filme III** | [/index3.html](https://inematds.github.io/inema-sitefilm/index3.html) | Lane B â€” Kie.ai Seedance v1 Lite (720p) | neon-geomÃ©trico, tÃºnel roxo/verde |
| **Code I** | [/lane-a.html](https://inematds.github.io/inema-sitefilm/lane-a.html) | Lane A â€” GSAP + Lenis puro | vertical, ciano, partÃ­culas em canvas |
| **Code II** | [/lane-a2.html](https://inematds.github.io/inema-sitefilm/lane-a2.html) | Lane A v2 â€” corrida horizontal pinada | Ã¢mbar, nÃºmeros outline, containerAnimation |

## Como cada filme foi feito

- **Filme I/II (Agnes, US$0):** 6 keyframes encadeados via img2img derivado (`agnes-image-2.1-flash`), 5 clipes interpolando pares Aâ†’B (`agnes-video-v2.0`, `mode:keyframes`), gate de SSIM em cada emenda. 141 frames de scrub em `frames/`.
- **Filme III (Kie.ai, ~112 crÃ©ditos):** cadeia Lane B verdadeira â€” cada clipe parte do **Ãºltimo frame real do anterior** (`bytedance/v1-lite-image-to-video`). 301 frames em `frames-kie/`. Runner: `kie-chain.sh` (upload â†’ createTask â†’ poll â†’ download â†’ extraÃ§Ã£o de frame â†’ SSIM). `fal-chain.sh` Ã© o runner equivalente para fal.ai.
- **Engine de scrub (Filmes):** canvas + ImageBitmap sliding window (decode fora da main thread), playhead com lerp, header com luminÃ¢ncia adaptativa, dissolve na cor da emenda do Ãºltimo frame.
- **Code I/II:** zero assets â€” sÃ³ GSAP/ScrollTrigger/Lenis de CDN; jank max ~17-19ms.

## VerificaÃ§Ã£o

Todas as pÃ¡ginas implementam o contrato de dev da skill: `?jump=<scrollY>` pousa prÃ©-rolado e `window.__ready` sinaliza pÃ¡gina pronta. `verify.js` (puppeteer-core + Chromium) tira screenshots em qualquer ponto do scroll e roda o teste de jank (p95/max de deltas de rAF, nunca FPS mÃ©dio).

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
lane-a2.html      Code II (GSAP horizontal Ã¢mbar)   verify.js     harness puppeteer
```

IntermediÃ¡rios de build (clipes brutos, keyframes) ficam fora do repo (`.gitignore`) â€” sÃ³ o runtime Ã© publicado. Nenhuma API key no repositÃ³rio.

---

<div align="center">
  <img src="capa/logo.svg" alt="Arckhé AI" height="32" />
  <p><strong>Arckhé AI</strong></p>
</div>