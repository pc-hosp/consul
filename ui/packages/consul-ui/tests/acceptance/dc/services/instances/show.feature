@setupApplicationTest
Feature: dc / services / instances / show: Show Service Instance
  Background:
    Given 1 datacenter model with the value "dc1"
    And 3 instance models from yaml
    ---
    - Service:
        ID: service-0-with-id
        Meta:
          external-source: consul
      Node:
        Node: node-0
    - Service:
        ID: service-1-with-id
        Tags: ['Tag1', 'Tag2']
        Meta:
          consul-dashboard-url: http://url.com
          external-source: nomad
          test-meta: test-meta-value
      Node:
        Node: another-node
      Checks:
        - Name: Service check
          ServiceID: service-0
          Output: Output of check
          Status: passing
        - Name: Service check
          ServiceID: service-0
          Output: Output of check
          Status: warning
        - Name: Service check
          Type: http
          ServiceID: service-0
          Output: Output of check
          Status: critical
        - Name: Node check
          ServiceID: ""
          Output: Output of check
          Status: passing
        - Name: Node check
          ServiceID: ""
          Output: Output of check
          Status: warning
        - Name: Node check
          ServiceID: ""
          Output: Output of check
          Status: critical
    - Service:
        ID: service-2-with-id
        Meta:
          external-source: kubernetes
          synthetic-node: true
      Node:
        Node: node-2
        Meta:
          synthetic-node: true
    ---
  Scenario: A Service instance has no Proxy
    Given 1 proxy model from yaml
    ---
    - ServiceProxy:
        DestinationServiceName: service-1
        DestinationServiceID: ~
    ---
    When I visit the instance page for yaml
    ---
      dc: dc1
      service: service-0
      node: another-node
      id: service-1-with-id
    ---
    Then the url should be /dc1/services/service-0/instances/another-node/service-1-with-id/health-checks
    Then I see externalSource like "nomad"
    And I see the text "another-node" in "[data-test-service-instance-node-name]"

    And I don't see upstreams on the tabs
    And I see healthChecksIsSelected on the tabs
    And I see 6 of the checks object

    When I click tags&Meta on the tabs
    And I see tags&MetaIsSelected on the tabs

    Then I see the text "Tag1" in "[data-test-tags] span:nth-child(1)"
    Then I see the text "Tag2" in "[data-test-tags] span:nth-child(2)"
    And I see 3 of the metadata object
    And the title should be "service-1-with-id - Consul"

  Scenario: A Service instance warns when deregistered whilst blocking
    Given 1 proxy model from yaml
    ---
    - ServiceProxy:
        DestinationServiceName: service-1
        DestinationServiceID: ~
    ---
    Given settings from yaml
    ---
    consul:client:
      blocking: 1
      throttle: 200
    ---
    And a network latency of 100
    When I visit the instance page for yaml
    ---
      dc: dc1
      service: service-0
      node: node-0
      id: service-0-with-id
    ---
    Then the url should be /dc1/services/service-0/instances/node-0/service-0-with-id/health-checks
    And an external edit results in 0 instance models
    And pause until I see the text "deregistered" in "[data-notification]"
  Scenario: A Service instance without a Proxy does not display Proxy Info tab
    Given 1 proxy model from yaml
    ---
    - ServiceProxy:
        DestinationServiceName: service-1
        DestinationServiceID: ~
    ---
    When I visit the instance page for yaml
    ---
      dc: dc1
      service: service-0
      node: node-0
      id: service-0-with-id
    ---
    Then the url should be /dc1/services/service-0/instances/node-0/service-0-with-id/health-checks
    And I don't see proxy on the tabs
  Scenario: A Service instance with a synthetic node does not display the node name
    When I visit the instance page for yaml
    ---
      dc: dc1
      service: service-2
      node: node-2
      id: service-2-with-id
    ---
    Then the url should be /dc1/services/service-2/instances/node-2/service-2-with-id/health-checks
    Then I see externalSource like "kubernetes"
    And I don't see the text "node-2" in "[data-test-service-instance-node-name]"
