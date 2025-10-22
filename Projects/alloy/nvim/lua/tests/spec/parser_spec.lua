-- ensure plugin lua dir is on package.path
local repo_root = vim.fn.getcwd()
package.path = repo_root .. "/lua/?.lua;" .. repo_root .. "/lua/?/init.lua;" .. package.path

local parser = require("core.parser")

describe("parser.get_parsed_pipeline_data", function()
  local test_bufnr

  before_each(function()
    test_bufnr = vim.api.nvim_create_buf(false, true)
  end)

  after_each(function()
    if vim.api.nvim_buf_is_valid(test_bufnr) then
      vim.api.nvim_buf_delete(test_bufnr, { force = true })
    end
  end)

  it("returns nil for invalid buffer", function()
    local components, chains, starts = parser.get_parsed_pipeline_data(nil)
    assert.is_nil(components)
    assert.is_nil(chains)
    assert.is_nil(starts)
  end)

  it("returns nil for empty buffer", function()
    vim.api.nvim_buf_set_lines(test_bufnr, 0, -1, false, {})
    local components, chains, starts = parser.get_parsed_pipeline_data(test_bufnr)
    assert.is_nil(components)
    assert.is_nil(chains)
    assert.is_nil(starts)
  end)

  it("parses simple component correctly", function()
    local content = {
      'prometheus.scrape "test" {',
      '  targets = [',
      '    {"__address__" = "localhost:9090"},',
      '  ]',
      '}',
    }
    vim.api.nvim_buf_set_lines(test_bufnr, 0, -1, false, content)

    local components, chains, starts = parser.get_parsed_pipeline_data(test_bufnr)

    assert.is_not_nil(components)
    assert.is_not_nil(chains)
    assert.is_not_nil(starts)
    assert.is_not_nil(components["prometheus.scrape.test"])
    assert.equal("prometheus.scrape", components["prometheus.scrape.test"].type)
    assert.equal("test", components["prometheus.scrape.test"].label)
    assert.equal(1, components["prometheus.scrape.test"].line)
    assert.equal(5, components["prometheus.scrape.test"].end_line)
  end)

  it("identifies start nodes correctly", function()
    local content = {
      'prometheus.scrape "source" {',
      '  targets = [{"__address__" = "localhost:9090"}]',
      '  forward_to = [prometheus.relabel.filter.receiver]',
      '}',
      '',
      'prometheus.relabel "filter" {',
      '  rule {',
      '    source_labels = ["__name__"]',
      '    target_label  = "job"',
      '  }',
      '  forward_to = [prometheus.remote_write.dest.receiver]',
      '}',
      '',
      'prometheus.remote_write "dest" {',
      '  endpoint {',
      '    url = "http://localhost:9009/api/v1/push"',
      '  }',
      '}',
    }
    vim.api.nvim_buf_set_lines(test_bufnr, 0, -1, false, content)

    local components, chains, starts = parser.get_parsed_pipeline_data(test_bufnr)

    assert.equal(1, #starts)
    assert.equal("prometheus.scrape.source", starts[1])
  end)

  it("builds forward_to relationships correctly", function()
    local content = {
      'prometheus.scrape "source" {',
      '  forward_to = [prometheus.relabel.filter.receiver]',
      '}',
      '',
      'prometheus.relabel "filter" {',
      '}',
    }
    vim.api.nvim_buf_set_lines(test_bufnr, 0, -1, false, content)

    local components, _, _ = parser.get_parsed_pipeline_data(test_bufnr)

    assert.is_not_nil(components["prometheus.scrape.source"].forward_to)
    assert.equal(1, #components["prometheus.scrape.source"].forward_to)
    assert.equal("prometheus.relabel.filter", components["prometheus.scrape.source"].forward_to[1])
    
    assert.is_not_nil(components["prometheus.relabel.filter"].receives_from)
    assert.equal(1, #components["prometheus.relabel.filter"].receives_from)
    assert.equal("prometheus.scrape.source", components["prometheus.relabel.filter"].receives_from[1])
  end)

  it("builds targets relationships correctly", function()
    local content = {
      'discovery.kubernetes "pods" {',
      '}',
      '',
      'prometheus.scrape "metrics" {',
      '  targets = discovery.kubernetes.pods.targets',
      '}',
    }
    vim.api.nvim_buf_set_lines(test_bufnr, 0, -1, false, content)

    local components, _, _ = parser.get_parsed_pipeline_data(test_bufnr)

    assert.is_not_nil(components["discovery.kubernetes.pods"].forward_to)
    assert.equal(1, #components["discovery.kubernetes.pods"].forward_to)
    assert.equal("prometheus.scrape.metrics", components["discovery.kubernetes.pods"].forward_to[1])
    
    assert.is_not_nil(components["prometheus.scrape.metrics"].receives_from)
    assert.equal(1, #components["prometheus.scrape.metrics"].receives_from)
    assert.equal("discovery.kubernetes.pods", components["prometheus.scrape.metrics"].receives_from[1])
  end)

  it("ignores comments when parsing", function()
    local content = {
      '// This is a comment',
      'prometheus.scrape "test" {',
      '  // Another comment',
      '  targets = [{"__address__" = "localhost:9090"}] // Inline comment',
      '  /* Block comment',
      '     spanning multiple lines */',
      '}',
    }
    vim.api.nvim_buf_set_lines(test_bufnr, 0, -1, false, content)

    local components, _, _ = parser.get_parsed_pipeline_data(test_bufnr)

    assert.is_not_nil(components["prometheus.scrape.test"])
    assert.equal("prometheus.scrape", components["prometheus.scrape.test"].type)
    assert.equal("test", components["prometheus.scrape.test"].label)
  end)

  it("handles complex pipeline chains", function()
    local content = {
      'prometheus.scrape "source" {',
      '  forward_to = [prometheus.relabel.step1.receiver]',
      '}',
      '',
      'prometheus.relabel "step1" {',
      '  forward_to = [prometheus.relabel.step2.receiver]',
      '}',
      '',
      'prometheus.relabel "step2" {',
      '  forward_to = [prometheus.remote_write.dest.receiver]',
      '}',
      '',
      'prometheus.remote_write "dest" {',
      '}',
    }
    vim.api.nvim_buf_set_lines(test_bufnr, 0, -1, false, content)

    local components, chains, starts = parser.get_parsed_pipeline_data(test_bufnr)

    assert.equal(1, #chains)
    assert.equal(4, #chains[1])
    assert.equal("prometheus.scrape.source", chains[1][1])
    assert.equal("prometheus.relabel.step1", chains[1][2])
    assert.equal("prometheus.relabel.step2", chains[1][3])
    assert.equal("prometheus.remote_write.dest", chains[1][4])
  end)

  it("detects multiple start nodes", function()
    local content = {
      'prometheus.scrape "source1" {',
      '  forward_to = [prometheus.remote_write.dest.receiver]',
      '}',
      '',
      'prometheus.scrape "source2" {',
      '  forward_to = [prometheus.remote_write.dest.receiver]',
      '}',
      '',
      'prometheus.remote_write "dest" {',
      '}',
    }
    vim.api.nvim_buf_set_lines(test_bufnr, 0, -1, false, content)

    local components, chains, starts = parser.get_parsed_pipeline_data(test_bufnr)

    assert.equal(2, #starts)
    assert.is_true(vim.tbl_contains(starts, "prometheus.scrape.source1"))
    assert.is_true(vim.tbl_contains(starts, "prometheus.scrape.source2"))
    assert.equal(2, #chains)
  end)

  it("caches results for identical content", function()
    local content = {
      'prometheus.scrape "test" {',
      '  targets = [{"__address__" = "localhost:9090"}]',
      '}',
    }
    vim.api.nvim_buf_set_lines(test_bufnr, 0, -1, false, content)

    -- First call
    local start_time = vim.loop.now()
    local components1, _, _ = parser.get_parsed_pipeline_data(test_bufnr)
    local first_call_time = vim.loop.now() - start_time

    -- Second call with same content should be faster (from cache)
    start_time = vim.loop.now()
    local components2, _, _ = parser.get_parsed_pipeline_data(test_bufnr)
    local second_call_time = vim.loop.now() - start_time

    assert.are.same(components1, components2)
    -- Second call should be significantly faster due to caching
    -- Note: This is a loose check as timing can vary
    assert.is_true(second_call_time <= first_call_time)
  end)

  it("handles malformed components gracefully", function()
    local content = {
      'prometheus.scrape "test" {',
      '  targets = [{"__address__" = "localhost:9090"}',
      -- Missing closing brace
    }
    vim.api.nvim_buf_set_lines(test_bufnr, 0, -1, false, content)

    local components, chains, starts = parser.get_parsed_pipeline_data(test_bufnr)

    -- Should handle malformed content without crashing
    assert.is_not_nil(components)
    assert.is_not_nil(chains)
    assert.is_not_nil(starts)
  end)
end)