A checklist for releasing the Gem:

* Test: `rake`
* Bump version in lib/cocoapod_check.rb
* Commit
* `git tag vXXX`
* `git push`
* `git push --tags`
* `gem build cocoapods-check.gemspec`
* `gem push cocoapods-check-XXX.gem`
* Create release on GitHub from tag
