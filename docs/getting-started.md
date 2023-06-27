# English version

Hi ! First of all, thank you for thinking about using our tools, and we hope that you're going to enjoy them. So how to get started ? The most important thing to understand primarily is how to use **squirrel**, our **package manager**.

## Squirrel

### Syncing repos
As we said before, **squirrel** is our package manager. It'll help you to install, remove, update, search and more generally to manage packages. It is based on a **very simple syntax** in order to let everyone use it without many issues of comprehension and this "How to get started ?" is here to destroy the little details you don't understand.

So, let's start. First, you should know that before installing any package, you **must** sync with the remote repos. **BUT**, before that, you must tell squirrel where to fetch the repos. On Stock Linux, by default, the configuration is already written but for some reason, if you want to try our package manager on some distro (you should not do that, it can break your system), you can follow the part below:

To do that, you have to create a configuration file: `/etc/squirrel.conf`. **YOU SHOULD CREATE THIS FILE ONLY IF IT IS NOT ALREADY CREATED**.

This is how this file should be in order to sync correctly with our repos:
```
stocklinux https://packages.stocklinux.org/x86_64/testing
```

You'll probably notice that the URL of the repo is ending with "testing". This is the name of what we call a "branch". It's a way to organize our repos.

On the testing branch, you're on a ultra-rolling release and **it is preferable not to be on this branch**. 
You should be on the branch named "rolling" in order to have a relatively stable system with one "big" update per month and continuous updates of "end-user apps" like Firefox, Discord, Spotify, etc...

So, you created (or just saw) this file. Now, the simple thing to do is to **open a terminal**, and **launch this command**:
```
sudo squirrel sync
```

Isn't that awesome and intuitive ? If the sync happenned correctly, you should see these messages inside your terminal:
```
Syncing repos...
Done !
```

### Installing packages

Installing a package is not a really hard thing to do. Indeed, all you have to do is to **open your terminal** and **launch this command**. Don't forget to replace "package" with the name of the package you want to install !
```
sudo squirrel install package
```

Congratulations ! You installed your first package !