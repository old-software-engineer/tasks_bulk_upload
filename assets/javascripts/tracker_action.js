 jQuery(document).on("ready turbolinks:load",function() {
  var project_ids = null

  function options_for_tracker(_this, options) {
       jQuery('option', _this).not(':disabled').remove();

       jQuery.each(options, function() {
           jQuery(_this).append( jQuery("<option></option>")
              .attr("value", this.id)
              .text(this.name));
      })
  }

  function set_options(type, options) {
      switch (type) {
          case 'tracker':
              var _this = document.getElementById('tracker_action_tracker');
              break;
          case 'custom_field':
              var _this = document.getElementById('tracker_action_custom_field');
              // code block
              break;
          case 'tracker_tasks':
              var _this = document.getElementById('parent_tracker_task');
               jQuery(_this).attr('data-options',JSON.stringify(options))
              // code block
              break;    
          default:
              // code block
      }
      if (options.length && type != 'tracker_tasks') {
        options_for_tracker(_this, options)
      } else {
          // alert("No option Found")
      }
  }

  function manual_ajax(url, data, type) {
       jQuery.ajax({
          url: url,
          data: data || {},
          async: false,
          type: type || 'GET',
          success: function(success) {
              set_options(success.type, success.options)
          },
          error: function(errors) {
              alert(errors.statusText);
          }
      });
  }

   jQuery(document).on('change', '[data-type="project"]', function() {
      project_ids =  jQuery(this).val();
      url = `/tracker/options/ jQuery{"tracker"}`
      data = { project_ids: project_ids }
      manual_ajax(url, data)
  })

   jQuery(document).on('change', '[data-type="tracker"]', function() {
      tracker_ids =  jQuery(this).val();
      url = `/tracker/options/ jQuery{"tracker_tasks"}`
      data = { tracker_ids: tracker_ids }
      manual_ajax(url, data)
  })

   jQuery(document).on('focus','[data-type="parent-tracker-task"]',function(){
    var availableTags = JSON.parse( jQuery('[data-type="parent-tracker-task"]').attr('data-options'))
       jQuery('[data-type="parent-tracker-task"]').autocomplete({
        source: availableTags,
         select: function( event, ui ) {
             jQuery( "#parent_tracker_task" ).val( ui.item.label );
             jQuery( "#parent-task-value" ).val( ui.item.value );
            return false;
          }
      });
  })


   jQuery.each(  jQuery('.col-left-section ul li'),function(){
    var link =  jQuery(this).children('a').attr('href')
    if(link == document.location.pathname){
       jQuery(this).addClass('tracker-active');
    }else{
       jQuery(this).removeClass('tracker-active');
    }

  })

})