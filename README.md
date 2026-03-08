# Ramadan Sim

I vibecoded this in 30 min for my friend's birthday 🎉🎂🥳

## GitHub Pages

This repo includes a Pages workflow at `.github/workflows/deploy.yml`.

For GitHub Pages, set `Settings -> Pages -> Source` to `GitHub Actions`.

The site will build with:

`flutter build web --release --base-href /ramadan_sim/`

For local web builds with asset optimization first, run:

`python tool/build_web.py --release --base-href /ramadan_sim/`
