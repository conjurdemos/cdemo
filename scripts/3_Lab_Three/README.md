# jenkins-e2e

An example of an end-to-end Conjur + Jenkins integration.
In this example, a Jenkins master assumes Conjur machine identity
by using Conjur's [Host Factory](https://developer.conjur.net/reference/services/host_factory/) auto-enrollment system.

## Requirements

* A modern version of Docker (~17.03.1) and `docker-compose` (~1.11.2) installed.
* Access to the `registry.tld/conjur-appliance-cuke-master:4.9-stable` image.

## Usage

### Setup

#### (Mostly) Automated

```sh-session
$ ./e2e.sh
```

When prompted for authentication, use username `admin` and password `secret`.

Note: to tear down the enviroment, use this: `docker-compose down -v`.

## Walkthrough

Once the environment is ready:
- Jenkins web UI is now available on port `8080`: http://localhost:8080.
- Conjur web UI is now available on port `443`: https://localhost/ui:

1. Log into Jenkins and run the 'poc' job.

- http://localhost:8080/job/poc/

2. View the audit of secret fetches in the Conjur web UI.

- https://localhost/ui/hosts/jenkins%2Fmasters%2Fmaster01/
- https://localhost/ui/variables/aws%2Fusers%2Fjenkins%2Faccess_key_id/
- https://localhost/ui/variables/aws%2Fusers%2Fjenkins%2Fsecret_access_key/

---

### Setup (Manual)

1. Start Conjur and Jenkins.

    ```sh-session
    $ docker-compose up -d
    ```

2. Load a Conjur policy for Jenkins.

    ```sh-session
    $ docker-compose exec conjur conjur policy load --as-group security_admin policy.yml
    ```

    If prompted for authentication, use `admin:secret`.

    This is also the username/password for the Conjur UI.
    In the Conjur UI, you can now see the policy: https://localhost/ui/policies/jenkins/.

    Load some values for the two variables we defined in policy.
    It doesn't really matter what the values are for this example:

    ```sh-session
    $ docker-compose exec conjur conjur variable values add aws/users/jenkins/access_key_id n8p9asdh89p
    Value added

    $ docker-compose exec conjur conjur variable values add aws/users/jenkins/secret_access_key 46s31x2x4rsf
    Value added
    ```

3. Assign Conjur identity to the Jenkins master.

    First, copy the Conjur public SSL cert to the Jenkins master:

    ```sh-session
    $ docker copy "$(docker-compose ps -q conjur):/opt/conjur/etc/ssl/ca.pem" conjur.pem
    $ docker copy conjur.pem "$(docker-compose ps -q jenkins):/etc/conjur.pem"
    ```

    Now apply a Conjur identity to the Jenkins master:

    ```sh-session
    docker-compose exec --user root jenkins /src/identify.sh
    ```
