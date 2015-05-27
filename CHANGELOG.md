## 0.6.1

##### Enhancements

* The `master` specs repo is updated before and after pushing a new spec to
  trunk.  
  [Samuel Giddins](https://github.com/segiddins)
  [#43](https://github.com/CocoaPods/cocoapods-trunk/issues/43)


## 0.6.0

##### Enhancements

* Allow specifying a Trunk token via the `COCOAPODS_TRUNK_TOKEN` environment
  variable.  
  [Samuel Giddins](https://github.com/segiddins)
  [CocoaPods#3224](https://github.com/CocoaPods/CocoaPods/issues/3224)


## 0.5.1

##### Enhancements

* Lint as a framework automatically. If needed, the `--use-libraries`
  option allows linting as a static library.  
  [Boris Bügling](https://github.com/neonichu)
  [#2912](https://github.com/CocoaPods/CocoaPods/issues/2912)

##### Bug Fixes

* Fix the detection of spec validation errors, and present the proper error
  (and messages) to the user.  
  [Orta Therox](https://github.com/orta)
  [#39](https://github.com/CocoaPods/cocoapods-trunk/issues/39)


## 0.5.0

##### Enhancements

* Added `pod trunk remove-owner` command to remove an owner from a pod.  
  [Samuel Giddins](https://github.com/segiddins)
  [#35](https://github.com/CocoaPods/cocoapods-trunk/issues/35)

* Added `pod trunk info` command to get information for a pod, including the
  owners.  
  [Kyle Fuller](https://github.com/kylef)
  [#15](https://github.com/CocoaPods/cocoapods-trunk/issues/15)


## 0.4.1

##### Enhancements

* Improved code readability and structure by splitting subcommands
  into individual files.  
  [Olivier Halligon](https://github.com/alisoftware)
  [#21](https://github.com/CocoaPods/CocoaPods/issues/21)

##### Bug Fixes

* Updates for changes in CocoaPods regarding `--allow-warnings`.  
  [Kyle Fuller](https://github.com/kylef)
  [Cocoapods#2831](https://github.com/CocoaPods/CocoaPods/pull/2831)


## 0.4.0

##### Bug Fixes

* Fixes installation issues with the JSON dependency.  
  [Eloy Durán](https://github.com/alloy)
  [CocoaPods#2773](https://github.com/CocoaPods/CocoaPods/issues/2773)

## 0.3.1

##### Bug Fixes

* Fixes an issue introduced with the release of `netrc 0.7.8`.  
  [Samuel Giddins](https://github.com/segiddins)
  [CocoaPods#2674](https://github.com/CocoaPods/CocoaPods/issues/2674)


## 0.3.0

##### Enhancements

* When linting, only allow dependencies from the 'master' specs repository.  
  [Samuel Giddins](https://github.com/segiddins)
  [#28](https://github.com/CocoaPods/cocoapods-trunk/issues/28)

##### Bug Fixes

* Fixes an issue where `pod trunk push` doesn't show which validation errors
  and just stated it failed.  
  [Kyle Fuller](https://github.com/kylef)
  [#26](https://github.com/CocoaPods/cocoapods-trunk/issues/26)


## 0.2.0

##### Enhancements

* Network errors are now gracefully handled.  
  [Samuel E. Giddins](https://github.com/segiddins)

* Adopted new argument format of CLAide.  
  [Olivier Halligon](https://github.com/AliSoftware)


## 0.1.0

* Initial release.
