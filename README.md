# R

This repository contains packages **CGR** which is not available from CRAN and **kinship** which has additional update. Links to packages I have maintained are as shown in the following table, with individual files listed by GitHub.

**Packages** | [CRAN](http://cran.r-project.org) | [GitHub](https://github.com/cran)
--------|---------------------------------------------|----------------------------
**gap** | https://cran.r-project.org/package=gap      | https://github.com/cran/gap
**gap.datasets** | https://cran.r-project.org/package=gap.datasets | https://github.com/cran/gap.datasets
**lmm** | https://cran.r-project.org/package=lmm      | https://github.com/cran/lmm
**pan** | https://cran.r-project.org/package=pan      | https://github.com/cran/pan
**tdthap**  | https://cran.r-project.org/package=tdthap | https://github.com/cran/tdthap
**kinship** | https://cran.r-project.org/src/contrib/Archive/kinship/ | https://github.com/cran/kinship

Packages **gap** and **tdthap** are featured in [task view for genetics](https://cran.r-project.org/web/views/Genetics.html), while packages **lmm** and **pan** are featured in [task view for social sciences](https://cran.r-project.org/web/views/SocialSciences.html).

You can install these packages either from CRAN, e.g., 
```
install.packages("pan", repos="https://cran.r-project.org")
```
or GitHub, 
```
library(devtools)
install_github("jinghuazhao/R/pan")
```
The Windows version of [kinship_1.1.4.zip][kinship_1.1.4.zip] is built from [kinship_1.1.4.tar.gz](kinship_1.1.4.tar.gz) using https://win-builder.r-project.org/.

I have earlier contributed to [**GGIR** package](https://cran.r-project.org/package=GGIR) via its `g.binread` function.

My recent contribution is to [**ITHIM** injurymodel](https://github.com/ithim/injurymodel).
