class Barbeque::AppsController < Barbeque::ApplicationController
  def index
    @apps = Barbeque::App.all
  end

  def show
    @app = Barbeque::App.find(params[:id])
  end

  def new
    @app = Barbeque::App.new
  end

  def edit
    @app = Barbeque::App.find(params[:id])
  end

  def create
    @app = Barbeque::App.new(params.require(:app).permit(:name, :docker_image, :description))

    if @app.save
      redirect_to @app, notice: 'App was successfully created.'
    else
      render :new
    end
  end

  def update
    @app = Barbeque::App.find(params[:id])
    # Name can't be changed after it's created.
    if @app.update(params.require(:app).permit(:docker_image, :description))
      redirect_to @app, notice: 'App was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @app = Barbeque::App.find(params[:id])
    @app.destroy
    redirect_to root_path, notice: 'App was successfully destroyed.'
  end
end
