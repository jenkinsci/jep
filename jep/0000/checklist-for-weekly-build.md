<!-- Checklist to transition Jenkins weekly build to require a newer Java version

https://github.com/jenkins-infra/helpdesk/issues/4135 is a good example for Java 17

-->

# Switch Jenkins Weekly Core Release to require Java 17

As per the [blog post](https://www.jenkins.io/blog/2024/06/11/require-java-17/), the upcoming Jenkins weekly release will require Java 17 or newer.

As such, we have to drop Java 11 from the build and release process and use Java 17.

Note: ci.jenkins.io builds of Jenkins Core are already running with Jav 17 and Java 21 on Linux: https://github.com/jenkinsci/jenkins/blob/master/Jenkinsfile

- [ ] Update the release pipeline as defined in the [release repository](https://github.com/jenkins-infra/release/blob/master/Jenkinsfile.d/core/release) to use the new minimum Java version
- [ ] Remove outdated Java references from the [native packaging scripts](https://github.com/jenkinsci/packaging)
- [ ] Update the Java version in the agent image, defined by a [PodTemplate](https://github.com/jenkins-infra/release/blob/master/PodTemplates.d/release-linux.yaml)
- [ ] Update the virtual machine definition from the agent template utilizes the `jenkinsciinfra/packaging` image.
      This image is defined in a [Dockerfile](https://github.com/jenkins-infra/docker-packaging/blob/main/Dockerfile)
- [ ] After the first weekly release to require a new Java version, Update the [Java support policy](https://www.jenkins.io/doc/book/platform-information/support-policy-java/)
