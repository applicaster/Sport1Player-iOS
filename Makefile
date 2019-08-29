documentation:
	@jazzy \
		--objc \
		--umbrella-header Sport1Player/Sport1Player.h \
		--framework-root Sport1Player \
		--sdk iphoneos \
		--min-acl internal \
		--no-hide-documentation-coverage \
		--theme fullwidth \
		--output ./docs \
		--documentation=./*.md
	@rm -rf ./build
