class AppsController < ApplicationController
  def index
    @apps = App.all
  end

  def show
    @app = App.find(params[:id])
  end

  def new
    @app = App.new
  end

  def edit
    @app = App.find(params[:id])
  end

  def create
    @app = App.new(params.require(:app).permit(:name, :docker_image, :description))

    if @app.save
      redirect_to @app, notice: 'App was successfully created.'
    else
      render :new
    end
  end

  def update
    @app = App.find(params[:id])
    # Name can't be changed after it's created.
    if @app.update(params.require(:app).permit(:docker_image, :description))
      redirect_to @app, notice: 'App was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @app = App.find(params[:id])
    @app.destroy
    redirect_to root_path, notice: 'App was successfully destroyed.'
  end
end
