module SiteHelper

  def site_name
    if current_site
      "#{current_site.title} de #{current_site.name}"
    else
      'Gobierto Presupuestos Municipales'
    end
  end

  def site_url
    if current_site
      current_site.domain
    else
      'presupuestos.gobierto.es'
    end
  end

  def url_host(url)
    URI.parse(url).host
  rescue
    url
  end

  def class_if(class_name, condition)
    if condition
      class_name
    else
      ''
    end
  end

end
