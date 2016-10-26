## 2016-10-26 Release 0.3.0
###Summary

New *fme\_service* type added.

####Features
* Partial management of FME services is now possible with the new `fme_service` type.  In particular, it is now possible to manage the URLs of services. This is required when configuring FME to run with HTTPS enabled.
* Checksumming of `fme_repository_item`s.  FME repository items are now reuploaded if they differ between the local copy and the server.

####Improvements
* Code refactoring after more rubocop cops enabled.

---

## 2016-03-08 Release 0.2.0
###Summary

New *fme\_resource* type added.

####Features
* FME resources can be uploaded with the new fme\_resource type.

####Bugfixes
* Providers won't prefetch resources until the fme\_api\_settings.yaml file is present.

####Improvements
* Puppet masters running on ruby 1.8 will now work.  The agent still requires at least ruby 1.9.

---

##2015-12-10 Release 0.1.0
###Summary

Initial release.  This is an alpha release with just a few types implemented.
