###

Hand Over

This script provides functionalities for the hand over process
 
###

class HandOver
  
  @setup = ()->
    @setup_assign_inventory_code()
    @setup_hand_over_button()
    @setup_add_item()
    
  @assign_through_autocomplete = (element, event)->
    $(event.target).val(element.item.inventory_code)
    $(event.target).closest("form").submit()
  
  @setup_assign_inventory_code = ()->
    $(".item_line .inventory_code form").live "ajax:beforeSend", ()->
      $(this).find(".icon").hide()
      $(this).find("input[type=text]").attr("disabled", true)
      $(this).append LoadingImage.get()
      $(this).find("input:focus").blur()
      
    $(".item_line .inventory_code form").live "ajax:success", (event, data)->
      $(this).closest(".line").replaceWith $.tmpl("tmpl/line", data)
      # notification
      Notification.add_headline
        title: "#{data.item.inventory_code}"
        text: "assigned to #{data.model.name}"
        type: "success"
        
    $(".item_line .inventory_code form").live "ajax:error", ()->
      $(this).find("input[type=text]").val("")
      
    $(".item_line .inventory_code form").live "ajax:complete", ->
      $(this).find(".loading").remove()
      $(this).find(".icon").show()
      $(this).find("input[type=text]").removeAttr("disabled")
      $(this).find("input[type=text]").autocomplete("destroy")
      $(this).closest(".line").removeClass "assigned"
      
    $(".item_line .inventory_code input").live "focus", (event)->
      $(this).data("value_on_focus", $(this).val())
    $(".item_line .inventory_code input").live "blur", (event)->
      if $(this).val() != $(this).data("value_on_focus")
        trigger = $(this)
        setTimeout ()->
          if $(trigger).siblings(".loading:visible").length == 0
            $(trigger).closest("form").submit()
        ,100
  
  @setup_hand_over_button = ()->
    $("#hand_over_button").on "click", ()->
      SelectionActions.storeSelectedLines()
      
  @update_visits = (data)->
    $('#visits').replaceWith($.tmpl("tmpl/visits", data))
    SelectionActions.set_target($('#visits'))
    SelectionActions.restoreSelectedLines()
    @update_subtitle()
  
  @setup_add_item: ->
    $('#add_item').bind "ajax:success", (xhr, data)->
      HandOver.add_line data
  
  @add_line: (line_data)->
    Notification.add_headline
      title: "+ #{Str.sliced_trunc(line_data.model.name, 36)}"
      text: "#{moment(line_data.start_date).sod().format(i18n.date.XL)}-#{moment(line_data.end_date).format(i18n.date.L)}"
      type: "success"
    # update availability for the lines with the same model
    lines_with_the_same_model = Underscore.filter $("#visits .line"), (line)-> $(line).tmplItem().data.model.id == line_data.model.id
    for line in lines_with_the_same_model 
      new_line_data = $(line).tmplItem().data 
      new_line_data.availability_for_inventory_pool = line_data.availability_for_inventory_pool
      HandOver.update_line(line, new_line_data)
    matching_line = Underscore.find $("#visits .line"), (line)-> $(line).tmplItem().data.id == line_data.id
    if matching_line?
      HandOver.update_line(matching_line, line_data)
    else 
      HandOver.add_new_line(line_data)
  
  @add_new_line: (line_data)->
    line_start_date = moment(line_data.start_date).sod()
    line_end_date = moment(line_data.end_date).sod()
    $(line_as_tmpl).find(".select input").attr("checked", true)
    # add template
    for visit in $(".visit")
      visit_date = moment($(visit).tmplItem().data.date).sod()
      if line_start_date.diff(visit_date, "days") < 0 # set new line before this visit
        new_visit = 
          action: line_data.contract.action
          date: line_data.start_date
          lines: [line_data]
          user: line_data.contract.user
        new_visit_tmpl = $.tmpl("tmpl/visit", new_visit)
        $(visit).before new_visit_tmpl
        return true
      else if line_start_date.diff(visit_date, "days") == 0 # set new line inside this visit
        for linegroup in $(visit).find(".linegroup")
          linegroup_start_date = moment($(linegroup).tmplItem().data.start_date).sod()
          linegroup_end_date = moment($(linegroup).tmplItem().data.end_date).sod()
          if linegroup_start_date.diff(line_start_date.toDate(), "days") < 0 # set new linegroup before this one
            new_linegroup_data = new GroupedLines([line_data])
            new_linegroup_tmpl = $.tmpl("tmpl/linegroup", new_linegroup_data)
            $(linegroup).closest(".indent").before new_linegroup_tmpl
            return true
          else if (linegroup_start_date.diff(line_start_date.toDate(), "days") == 0) and (linegroup_end_date.diff(line_end_date.toDate(), "days") == 0)
            line_as_tmpl = $.tmpl("tmpl/line", line_data)
            $(linegroup).find(".lines").append line_as_tmpl
            return true
        # set new linegroup after the last linegroup
        new_linegroup_data = new GroupedLines([line_data])
        new_linegroup_tmpl = $.tmpl("tmpl/linegroup", new_linegroup_data)
        $(visit).find(".linegroup:last").closest(".indent").after new_linegroup_tmpl                
        return true
    # set new line after the last visit
    new_visit = 
      action: line_data.contract.action
      date: line_data.start_date
      lines: [line_data]
      user: line_data.contract.user
    new_visit_tmpl = $.tmpl("tmpl/visit", new_visit)
    $(".visit:last").after new_visit_tmpl
  
  @update_line = (line_element, line_data)->
    new_line = $.tmpl("tmpl/line", line_data)
    $(line_element).replaceWith new_line
  
  @update_subtitle = ->
    console.log "UPDATE SUBTITLE"
    # var subtitle_text = $("#acknowledge .subtitle").html();
    # subtitle_text.replace(/^\d+/, order.quantity);
    # subtitle_text.replace(/\s\d+/, " "+new MaxRange(order.lines).value);
    # $("#acknowledge .subtitle").html(subtitle_text);
  
window.HandOver = HandOver