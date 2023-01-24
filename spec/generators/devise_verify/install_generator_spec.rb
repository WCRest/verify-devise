# frozen_string_literal: true
require "generators/devise_verify/install_generator"

RSpec.describe DeviseVerify::Generators::InstallGenerator, type: :generator do
  destination File.expand_path("../../tmp", __FILE__)

  after(:all) do
    prepare_destination
  end

  def prepare_app
    FileUtils.mkdir_p(File.join(destination_root, "config", "initializers"))
    File.open(File.join(destination_root, "config", "initializers", "devise.rb"), "w") do |file|
      file << "Devise.setup do |config|\n\nend"
    end
  end

  def prepare_html_layout
    FileUtils.mkdir_p(File.join(destination_root, "app", "views", "layouts"))
    File.open(File.join(destination_root, "app", "views", "layouts", "application.html.erb"), "w") do |file|
      file << "<html><head><title>Application</title></head><body></body></html>"
    end
  end

  describe "with no arguments" do
    before(:all) do
      prepare_destination
      prepare_app
      prepare_html_layout
      run_generator
    end

    it "copies across the locale file" do
      expect(destination_root).to have_structure {
        directory "config" do
          directory "locales" do
            file "devise.verify.en.yml" do
              contains "Two factor authentication was enabled"
            end
          end
        end
      }
    end

    it "injects devise config" do
      devise_config = File.read(File.join(destination_root, "config", "initializers", "devise.rb"))
      expect(devise_config).to match("Devise Verify Authentication Extension")
      expect(devise_config).to match("# config.verify_remember_device = 1.month")
      expect(devise_config).to match("# config.verify_enable_onetouch = false")
      expect(devise_config).to match("# config.verify_enable_qr_code = false")
    end

    it "creates an verify initializer" do
      expect(destination_root).to have_structure {
        directory "config" do
          directory "initializers" do
            file "verify.rb" do
              contains "Verify.api_key = ENV[\"AUTHY_API_KEY\"]\n"
              contains "Verify.api_uri = \"https://api.verify.com/\""
            end
          end
        end
      }
    end

    it "copies over the HTML views" do
      expect(destination_root).to have_structure {
        directory "app" do
          directory "views" do
            directory "devise" do
              directory "devise_verify" do
                file "enable_verify.html.erb"
                file "verify_verify_installation.html.erb"
                file "verify_verify.html.erb"
              end
            end
          end
        end
      }
    end

    it "copies over the CSS and JS assets" do
      expect(destination_root).to have_structure {
        directory "app" do
          directory "assets" do
            directory "stylesheets" do
              file "devise_verify.css"
            end
            directory "javascripts" do
              file "devise_verify.js"
            end
          end
        end
      }
    end

    it "injects JS and CSS into the head of the application layout" do
      expect(destination_root).to have_structure {
        directory "app" do
          directory "views" do
            directory "layouts" do
              file "application.html.erb" do
                contains "<%=javascript_include_tag \"https://www.verify.com/form.verify.min.js\" %>"
                contains "<%=stylesheet_link_tag \"https://www.verify.com/form.verify.min.css\" %>"
              end
            end
          end
        end
      }
    end
  end

  describe "with haml views" do
    before(:all) do
      prepare_destination
      prepare_app
      prepare_html_layout
      run_generator %w(--haml)
    end

    it "copies over the HAML views" do
      expect(destination_root).to have_structure {
        directory "app" do
          directory "views" do
            directory "devise" do
              directory "devise_verify" do
                file "enable_verify.html.haml"
                file "verify_verify_installation.html.haml"
                file "verify_verify.html.haml"
              end
            end
          end
        end
      }
    end
  end

  describe "with sass" do
    before(:all) do
      prepare_destination
      prepare_app
      prepare_html_layout
      run_generator %w(--sass)
    end

    it "copies over SASS and JS assets" do
      expect(destination_root).to have_structure {
        directory "app" do
          directory "assets" do
            directory "stylesheets" do
              file "devise_verify.sass"
            end
            directory "javascripts" do
              file "devise_verify.js"
            end
          end
        end
      }
    end
  end
end