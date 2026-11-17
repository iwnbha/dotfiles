return {
  {
    "rcarriga/nvim-dap-ui",
    enabled = false,
  },
  {
    "mfussenegger/nvim-dap",
    dependencies = { "igorlfs/nvim-dap-view" },
    opts = function()
      local dap = require("dap")
      dap.listeners.after.initialize["dotfiles-codelldb"] = function(session)
        if session.config.type ~= "codelldb" then
          return
        end
        -- dap-view caches exception filters by adapter. CodeLLDB can replace
        -- its C++ filters with Rust filters after launch, even for the same adapter.
        local set_exception_breakpoints = session.set_exception_breakpoints
        function session:set_exception_breakpoints(filters, options, on_done)
          local available = self.capabilities.exceptionBreakpointFilters
          if type(filters) == "table" and #filters > 0 and available then
            local supported = {}
            for _, option in ipairs(available) do
              supported[option.filter] = true
            end
            filters = vim.tbl_filter(function(id)
              return supported[id]
            end, filters)
            -- A stale update must not clear the session's active filters.
            if #filters == 0 then
              if on_done then
                on_done()
              end
              return
            end
          end
          return set_exception_breakpoints(self, filters, options, on_done)
        end
      end
    end,
  },
  {
    "igorlfs/nvim-dap-view",
    version = "v1.2.1",
    opts = {
      auto_toggle = true,
      windows = {
        position = "below",
        size = 0.25,
      },
    },
    keys = {
      {
        "<leader>du",
        function()
          require("dap-view").toggle()
        end,
        desc = "Dap View",
      },
      {
        "<leader>de",
        function()
          require("dap-view").hover(nil, true)
        end,
        desc = "Eval",
        mode = { "n", "x" },
      },
    },
  },
}
