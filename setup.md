---
title: Setup
---

<!--
FIXME: Setup instructions live in this document. Please specify the tools and
the data sets the Learner needs to have installed.

## Data Sets

FIXME: place any data you want learners to use in `episodes/data` and then use
       a relative link ( [data zip file](data/lesson-data.zip) ) to provide a
       link to it, replacing the example.com link.

Download the [data zip file](https://example.com/FIXME) and unzip it to your Desktop
-->

## Software Setup

::::::::::::::::::::::::::::::::::::::: discussion

### Install a Linux Shell Environment

:::::::::::::::::::::::::::::::::::::::::::::::::::


:::::::::::::::: solution

#### Windows

- Download the Git for Windows [installer](https://gitforwindows.org/)
- Run the installer and follow the steps below:
	1. Git Setup
	   		+ Click on "Next" four times (two times if you've previously

:::::::::::::::::::::::::


:::::::::::::::: solution

#### MacOS


The default shell in some versions of macOS is Bash, and
Bash is available in all versions, so no need to install anything.
You access Bash from the Terminal (found in `/Applications/Utilities`).
See the Git installation [video tutorial](#macvid)
for an example on how to open the Terminal.
You may want to keep Terminal in your dock for this workshop.
            
To see if your default shell is Bash type `echo $SHELL`
in Terminal and press the <kbd>Return</kbd> key. If the message
printed does not end with '/bash' then your default is something
else and you can run Bash by typing `bash`.

If you want to change your default shell, see
[this Apple Support article](https://support.apple.com/en-au/HT208050)
and follow the instructions on "How to change your default shell".
        
##### Video Tutorial {#macvid}

<div>
<iframe type="text/html" style="width:50%;" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" src="https://www.youtube-nocookie.com/embed/9LQhwETCdwY?modestbra
nding=1&playsinline=1&iv_load_policy=3&rel=0"></iframe>
</div>

:::::::::::::::::::::::::


:::::::::::::::: solution

#### Linux

The default shell is usually Bash and there is usually no need to
install anything.
          
To see if your default shell is Bash type `echo $SHELL` in
a terminal and press the <kbd>Enter</kbd> key. If the message printed
does not end with '/bash' then your default is something else and you
can run Bash by typing `bash`.


:::::::::::::::::::::::::


::::::::::::::::::::::::::::::::::::::: discussion

### Install R and RStudio

R and RStudio are two separate pieces of software:

- **R** is a programming language that is especially powerful for data
  exploration, visualization, and statistical analysis
- **RStudio** is an integrated development environment (IDE) that makes using
  R easier. In this course we use RStudio to interact with R.

If you don't already have R and RStudio installed, follow the instructions for
your operating system below. You have to install R before you install RStudio.

:::::::::::::::::::::::::::::::::::::::::::::::::::

:::::::::::::::: solution

#### Windows

- Download R from the
  [CRAN website](https://cran.r-project.org/bin/windows/base/release.htm).
- Run the `.exe` file that was just downloaded
- Go to the [RStudio download page](https://www.rstudio.com/products/rstudio/download/#download)
- Under *All Installers*, download the RStudio Installer for Windows.
- Double click the file to install it
- Once it's installed, open RStudio to make sure it works and you don't get any
  error messages.

:::::::::::::::::::::::::


:::::::::::::::: solution

#### MacOS

- Download R from
  the [CRAN website](https://cran.r-project.org/bin/macosx/).
- Select the `.pkg` file for the latest R version
- Double click on the downloaded file to install R
- It is also a good idea to install [XQuartz](https://www.xquartz.org/) (needed
  by some packages)
- Go to the [RStudio download page](https://www.rstudio.com/products/rstudio/download/#download)
- Under *All Installers*, download the RStudio Installer for MacOS.
- Double click the file to install RStudio
- Once it's installed, open RStudio to make sure it works and you don't get any
  error messages.

:::::::::::::::::::::::::


:::::::::::::::: solution

#### Linux

- Follow the instructions for your distribution
  from [CRAN](https://cloud.r-project.org/bin/linux), they provide information
  to get the most recent version of R for common distributions.
- Go to the
  [RStudio download page](https://www.rstudio.com/products/rstudio/download/#download)
- Under *All Installers*, select the version that matches your distribution and
  install it with your preferred method
  (e.g., with Debian/Ubuntu `sudo dpkg -i rstudio-YYYY.MM.X-ZZZ-amd64.deb` at the terminal).
- Once it's installed, open RStudio to make sure it works and you don't get any
  error messages.

:::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::::: discussion

### Update R and RStudio

If you already have R and RStudio installed, first check if your R version is
up to date:

- When you open RStudio your R version will be printed in the console on
  the bottom left. Alternatively, you can type `sessionInfo()` into the console.
  If your R version is 4.0.0 or later, you don't need to update R for this
  lesson. If your version of R is older than that, download and install the
  latest version of R from the R project website
  [for Windows](https://cran.r-project.org/bin/windows/base/),
  [for MacOS](https://cran.r-project.org/bin/macosx/),
  or [for Linux](https://cran.r-project.org/bin/linux/)
- It is not necessary to remove old versions of R from your system,
  but if you wish to do so you can check
  [How do I uninstall R?](https://cran.r-project.org/bin/windows/base/rw-FAQ.html#How-do-I-UNinstall-R_003f)
- Note: The changes introduced by new R versions are usually backwards-compatible.
  That is, your old code should still work after updating your R version.
  However, if breaking changes happen, it is useful to know that you can have
  multiple versions of R installed in parallel and that you can switch between
  them in RStudio by going to `Tools > Global Options > General > Basic`.
- After installing a new version of R, you will have to reinstall all your packages
  with the new version. For Windows, there is a package called `installr` that can
  help you with upgrading your R version and migrate your package library.

To update RStudio to the latest version, open RStudio and click on
`Help > Check for Updates`. If a new version is available follow the
instruction on screen. By default, RStudio will also automatically notify you
of new versions every once in a while.

### Install required R packages

During the course we will need a number of R packages. Packages contain useful
R code written by other people. We will use the packages
`pbdR`, `pbdML`, `pbdMPI`, `pbdMAT`, `flexiblas`, `parallel`, and `randomForest`.

To try to install these packages, open RStudio and copy and paste the following
command into the console window (look for a blinking cursor on the bottom left),
then press the <kbd>Enter</kbd> (Windows and Linux) or <kbd>Return</kbd> (MacOS)
to execute the command.


```r
install.packages(c("pbdR", "pbdML", "pbdMPI", "pbdMAT",
		   "flexiblas", "parallel", "randomForest"))
```

Alternatively, you can install the packages using RStudio's graphical user
interface by going to `Tools > Install Packages` and typing the names of the
packages separated by a comma.

R tries to download and install the packages on your machine.
When the installation has finished, you can try to load the
packages by pasting the following code into the console:


```r
library(pbdR)
library(pbdML)
library(pbdMPI)
library(pbdMAT)
library(flexiblas)
library(parallel)
library(randomForest)
```

If you do not see an error like `there is no package called ‘...'` you are good
to go!

### Updating R packages

Generally, it is recommended to keep your R version and all packages
up to date, because new versions bring improvements and important bugfixes.
To update the packages that you have installed, click `Update` in the
`Packages` tab in the bottom right panel of RStudio, or go to
`Tools > Check for Package Updates...`.

Sometimes, package updates introduce changes that break your old code,
which can be very frustrating. To avoid this problem, you can use a package
called `renv`. It locks the package versions you have used for a given project
and makes it straightforward to reinstall those exact package version in a
new environment, for example after updating your R version or on another
computer. However, the details are outside of the scope of this lesson.

:::::::::::::::::::::::::::::::::::::::::::::::::::
