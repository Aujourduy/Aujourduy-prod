class PwaController < ApplicationController
  skip_forgery_protection
  
  def manifest
    response.headers['Cache-Control'] = 'public, max-age=0, must-revalidate'
    render 'pwa/manifest', layout: false, content_type: 'application/json; charset=utf-8'
  end
  
  def service_worker
    response.headers['Cache-Control'] = 'public, max-age=0, must-revalidate'
    render 'pwa/service_worker', layout: false, content_type: 'application/javascript'
  end
end
