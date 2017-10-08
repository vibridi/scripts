# Scripts

These are bash scripts for automating common tasks.
This folder includes:
- **initjp** a script for setting up projects
- **tronco** a scripts for managing credentials with GPG


## INITJP

initjp helps set up new Java projects. In particular, it can take care of the following three common steps:
- create a maven project  
- initialize a local GIT repository
- initialize a remote GIT repository

### Usage

Create a maven project

``` initjp -m ```

The script will ask you to input the `groupId`, `artifactId` and the name of the main class.
Then it will ask what maven archetype to use, from the following:
[1] maven-archetype-archetype
[2] maven-archetype-quickstart
[3] maven-archetype-webapp
[4] java8-archetype
[5] javafx-archetype
[6] pom-root
 
The script is currently customized to work with a few archetypes that I have in my local system, namely java8-archetype and [javafx-archetype](https://github.com/vibridi/javafx-archetype)). You can easily adapt it to your specific needs. 


Create a local GIT repository. 
Provided you have git installed, you can run:

``` initjp -i ```


Create a remote GIT repository
Provided you have git installed, you can run:

``` initjp -g <repo_name> ```

If you also chose the `-m` option, you can omit the repo name and the script will use the maven `artifactId` value. 


## TRONCO 

Tronco is a utility for managing usernames and passwords with GPG. Provided you have GPG installed, the script will encrypt your credentials in a local hidden folder and decrypt them when you want to see the content.


### Installation

Create a hidden folder in your home path:

``` mkdir ~/.tronco ```

Done. The first time you launch the script with any option, it will prompt for a GPG user id that it will use later on to encrypt your credentials.


### Usage

Create a new set of credentials:

``` tronco -a <service_name> ```


Show an existing set of credentials:

``` tronco -s <service_name> ```


Show an existing set of credentials and copy the password to your clipboard (works on Mac):

``` tronco -s <service_name> -c ```


Modify an existing set of credentials:

``` tronco -e <service_name> -c ```


Remove an existing set of credentials:

``` tronco -r <service_name> -c ```



## Authors

* **Gabriele Vaccari** - *Initial work* - [Vibridi](https://github.com/vibridi/)

Currently there are no other contributors


## TODOs

- remove the reference to this GIT repo from `initjp`


## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details
