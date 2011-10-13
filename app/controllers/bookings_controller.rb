# encoding: UTF-8
class BookingsController < ApplicationController

  # GET /bookings
  # GET /bookings.xml
  def index
    # Tar fram alla ohanterade beställningar samt avbokade beställningar där utropstiden inte har passerat ännu
    @bookings = Booking.where("status = :bokad OR status = :avb_status AND utrop > :current_time",
      {:bokad => "bokad", :avb_status => "avb", :current_time => DateTime.current}).order("utrop")

    # Tar reda på tiden som återstår till nästa utrop och delar upp det i variabler som används av javaScript:et för
    # timer-klockan
    @utropstider = @bookings.all(:select => "utrop").map(&:utrop)
    @utropstider.sort!
    @nasta_utropstid = @utropstider.first
    @ar = @nasta_utropstid.to_s[0,4]
    @manad = @nasta_utropstid.to_s[5,2]
    @manad = @manad.to_i
    @manad = @manad - 1
    @dag = @nasta_utropstid.to_s[8,2]
    @timme = @nasta_utropstid.to_s[11,2]
    @minut = @nasta_utropstid.to_s[14,2]
    @sekund = @nasta_utropstid.to_s[17,2]

    # Variabel för ny bokning
    @edit_booking = Booking.new

    # Variabel som talar om vilken action som användes senast för att lista beställningar och därmed vilken visningsvy
    # som ska användas vid AJAX-anrop
    @came_from = "index"

    respond_to do |format|
      format.html # index.html.erb
      format.js
    end
  end

  def one_day
    @bookings = Booking.where("status = :bokad AND utrop <= :one_day_forward OR status = :avb_status AND utrop BETWEEN :current_time AND :one_day_forward",
      {:bokad => "bokad", :one_day_forward => DateTime.current + 1.day, :avb_status => "avb", :current_time => DateTime.current}).order("utrop")

    @edit_booking = Booking.new

    @came_from = "one_day"

    render 'bookings/index'

  end

  def one_week
    @bookings = Booking.where("status = :bokad AND utrop <= :one_week_forward OR status = :avb_status AND utrop BETWEEN :current_time AND :one_week_forward",
      {:bokad => "bokad", :one_week_forward => DateTime.current + 1.week, :avb_status => "avb", :current_time => DateTime.current}).order("utrop")

    @edit_booking = Booking.new

    @came_from = "one_week"

    render 'bookings/index'

  end

  def one_month
    @bookings = Booking.where("status = :bokad AND utrop <= :one_month_forward OR status = :avb_status AND utrop BETWEEN :current_time AND :one_month_forward",
      {:bokad => "bokad", :one_month_forward => DateTime.current + 1.month, :avb_status => "avb", :current_time => DateTime.current}).order("utrop")

    @edit_booking = Booking.new

    @came_from = "one_month"

    render 'bookings/index'

  end

  def utdelade
    @bookings = Booking.where(:status => ["klar","bom","avb"]).order("updated_at DESC")

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @bookings }
    end
  end

  # GET /bookings/1
  # GET /bookings/1.xml
  def show
    @booking = Booking.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @booking }
    end
  end

  # GET /bookings/new
  # GET /bookings/new.xml
  def new
    @booking = Booking.new

    respond_to do |format|
      format.html # new.html.erb
      format.js
    end
  end

  # GET /bookings/1/edit
  def edit
    @edit_booking = Booking.find(params[:id])
  end

  # POST /bookings
  # POST /bookings.xml
  def create
    @edit_booking = Booking.new(params[:booking])

    respond_to do |format|
      @edit_booking.utrop = @edit_booking.hamttid - @edit_booking.utroptimmar.hours - @edit_booking.utropminuter.minutes
      if @edit_booking.save
        format.html { redirect_to(:action => 'index', :notice => 'Booking was successfully created.') }
        format.js { redirect_to(:action => 'index') }
      else
        format.html { render :action => "index" }
        format.js { redirect_to(:action => 'index') }
      end
    end
  end

  def duplicate
 #   @came_from = flash[:notice]
    @old_booking = Booking.find(params[:id])
    @new_booking = Booking.new
    @new_booking.anm = @old_booking.anm
    @new_booking.utrop = @old_booking.utrop
    @new_booking.fran = @old_booking.fran
    @new_booking.hamttid = @old_booking.hamttid
    @new_booking.mottagare = @old_booking.mottagare
    @new_booking.namn = @old_booking.namn
    @new_booking.status = 'bokad'
    @new_booking.telefonnr = @old_booking.telefonnr
    @new_booking.till = @old_booking.till
    respond_to do |format|
      if @new_booking.save
        format.html { redirect_to(:action => 'index', :notice => "hännä geck som brau!") }
        format.js { redirect_to(:action => '#{@@came_from}')}
      else
        format.html { render :action => "index" }
        format.js
      end
    end

  end

  def retur
    @old_booking = Booking.find(params[:id])
    @new_booking = Booking.new
    @new_booking.anm = @old_booking.anm
    @new_booking.utrop = @old_booking.utrop
    @new_booking.fran = @old_booking.till
    @new_booking.hamttid = @old_booking.hamttid
    @new_booking.mottagare = @old_booking.mottagare
    @new_booking.namn = @old_booking.namn
    @new_booking.status = 'bokad'
    @new_booking.telefonnr = @old_booking.telefonnr
    @new_booking.till = @old_booking.fran
    respond_to do |format| # TODO gör så att posten inte sparas om man stänger fönstret utan att klicka på "boka"
      if @new_booking.save
        format.html { redirect_to( edit_booking_path(@new_booking), :notice => "Ange ny utrops- och hämttid") }
        format.xml  { render :xml => @new_booking, :status => :created, :location => @new_booking }
      else
        format.html { render :action => "index" }
        format.xml  { render :xml => @new_booking.errors, :status => :unprocessable_entity }
      end
    end

  end


  # PUT /bookings/1
  # PUT /bookings/1.xml
  def update
    @edit_booking = Booking.find(params[:id])

    respond_to do |format|
      if @edit_booking.update_attributes(params[:booking])
        @edit_booking.utrop = @edit_booking.hamttid - @edit_booking.utroptimmar.hours - @edit_booking.utropminuter.minutes
        @edit_booking.save
        format.html { redirect_to(:action => 'index', :notice => 'Booking was successfully updated.') }
        format.js {render :action => 'index'}
      else
        format.html { render :action => "edit" }
        format.js {render :action => 'edit'}
      end
    end
  end

  def delaut
    @booking = Booking.find(params[:id])

    respond_to do |format|
      format.html
      format.xml  { head :ok }
    end

  end

  def andrabil
    @booking = Booking.find(params[:id])

    respond_to do |format|
      format.html
      format.xml  { head :ok }
    end

  end

  def avb
    @booking = Booking.find(params[:id])
    if @booking.status != "bom"
      @booking.status = "avb"
      respond_to do |format|
        if @booking.save
          format.html {redirect_to(:action => 'index')}
          format.xml  { head :ok }
        else
          format.html { redirect_to(:action => 'index', :notice => 'Avbokning misslyckades!') }
          format.xml  { render :xml => @booking.errors, :status => :unprocessable_entity }
        end
      end
    else
      redirect_to(:action => 'index', :notice => 'KAN INTE AVBOKA EN BOMKÖRNING')
    end

  end

  def reclaim
    @booking = Booking.find(params[:id])
    @booking.status = "bokad"
    respond_to do |format|
      if @booking.save
        format.html {redirect_to(:action => 'index')}
        format.xml  { head :ok }
      else
        format.html { redirect_to(:action => 'index', :notice => 'Återbokning misslyckades!') }
        format.xml  { render :xml => @booking.errors, :status => :unprocessable_entity }
      end
    end

  end

  def bom
    @booking = Booking.find(params[:id])
    if @booking.status == "klar"
      @booking.status = "bom"
      respond_to do |format|
        if @booking.save
          format.html {redirect_to(:action => 'index')}
          format.xml  { head :ok }
        else
          format.html { redirect_to(:action => 'index', :notice => 'bomning misslyckades!') }
          format.xml  { render :xml => @booking.errors, :status => :unprocessable_entity }
        end
      end
    else
      redirect_to(:action => 'index', :notice => "KAN INTE BOM:A EN ICKE UTDELAD KÖRNING")
    end

  end

  # DELETE /bookings/1
  # DELETE /bookings/1.xml
  def destroy
    @booking = Booking.find(params[:id])
    @booking.destroy

    respond_to do |format|
      format.html { redirect_to(bookings_url) }
      format.xml  { head :ok }
    end
  end
end
