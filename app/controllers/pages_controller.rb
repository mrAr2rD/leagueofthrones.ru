class PagesController < ApplicationController
  def rules
    @page = SitePage.find_by_slug!("rules")
  end
end
