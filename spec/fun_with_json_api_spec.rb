require 'spec_helper'

describe FunWithJsonApi do
  it 'should have a Semantic Versioning compatible VERSION' do
    # based on https://github.com/npm/node-semver/issues/32
    version_regex = /
      \A([0-9]+) # major
      \.([0-9]+) # minor
      \.([0-9]+) # patch
      (?:-([0-9A-Za-z-]+(?:\.[0-9a-z-]+)*))? # build
      (?:\+[0-9a-z-]+)?\z # tag
    /x
    expect(FunWithJsonApi::VERSION).to match(version_regex)
  end
end
