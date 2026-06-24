# frozen_string_literal: true

module Pave
  class Configuration
    attr_reader :runtime_root, :products_root, :plugins_root

    def initialize(root: Pathname.pwd)
      root = Pathname(root)
      self.runtime_root = root.join("runtime")
      self.products_root = root.join("products")
      self.plugins_root = root.join("plugins")
    end

    attr_writer :backoffice_path

    def backoffice_path
      @backoffice_path || "/admin"
    end

    def runtime_root=(path)
      @runtime_root = Pathname(path)
    end

    def products_root=(path)
      @products_root = Pathname(path)
    end

    def plugins_root=(path)
      @plugins_root = Pathname(path)
    end

    def product(...)
      Pave.product(...)
    end

    def tenant_chrome(...)
      Pave.tenant_chrome(...)
    end

    def tenant_settings(...)
      Pave.tenant_settings(...)
    end

    def after_sign_in_redirect(...)
      Pave.after_sign_in_redirect(...)
    end

    def after_sign_up_redirect(...)
      Pave.after_sign_up_redirect(...)
    end

    def signed_in_root_redirect(...)
      Pave.signed_in_root_redirect(...)
    end

    def products
      Pave.products
    end

    def backoffice
      Pave.backoffice
    end
  end
end
