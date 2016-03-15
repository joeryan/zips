class Zip
  include ActiveModel::Model

  attr_accessor :id, :city, :state, :population

  def to_s
    "#{@id}: #{@city}, #{@state}, pop=#{@population}"
  end

  def initialize(params={})
    #switch between both internal and external views of id and population
    @id=params[:_id].nil? ? params[:id] : params[:_id]
    @city=params[:city]
    @state=params[:state]
    @population=params[:pop].nil? ? params[:population] : params[:pop]
  end

  # convinience method for console access to default db
  def self.mongo_client
    Mongoid::Clients.default
  end

  # convincence method to access zips_development in console
  def self.collection
    self.mongo_client['zips']
  end

  def self.all (prototype={}, sort={:population => -1}, offset=0, limit=100)
    tmp = {}
    sort.each {|k,v|
      k = k.to_sym==:population ? :pop : k.to_sym
      tmp[k] = v if [:city, :state, :pop].include?(k)
    }
    sort = tmp
    prototype.each_with_object({}) {|(k,v), tmp| tmp[k.to_sym] = v; tmp}

    Rails.logger.debug {"getting all zips, prototype=#{prototype}, sort=#{sort}, offset=#{offset}, limit=#{limit}"}

    result=collection.find(prototype)
                      .projection({_id:true, city:true, state:true, pop:true})
                      .sort(sort)
                      .skip(offset)
    result=result.limit(limit) if !limit.nil?

    return result
  end

  def destroy
  end

  def self.find(id)
    Rails.logger.debug {"getting zip #{id}"}

    doc = self.collection.find(:_id=>id)
                    .projection({_id:true, city:true, state:true, pop:true})
                    .first
    return doc.nil? ? nil : Zip.new(doc)
  end

  def update(updates)
    Rails.logger.debug {"Updating #{self} with #{updates}"}

    # map the :population term to internal :pop term
    updates[:pop] = updates[:population] if !updates[:population].nil?
    updates.slice!(:city, :state, :pop) if !updates.nil?

    self.class.collection
              .find(_id:@id)
              .update_one(:$set => updates)
  end

  def save
    Rails.logger.debug {"Saving #{self}"}

    result=self.class.collection
              .insert_one(_id:@id, city:@city, state:@state, pop:@population)
    @id = result.inserted_id
  end

end
