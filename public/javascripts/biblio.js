/**** multi ****/

function multiAddNote()
{
  var responsibility = jQuery('#multiPlus_note > textarea')[0].value;
  var annotation     = jQuery('#multiPlus_note > textarea')[1].value

  var index = multiGetNextIndex('note');

  var item = '<li>' +                
             '  <textarea class="observechange responsibility" id="biblio_identifier_note_' + index + '_responsibility" name="biblio_identifier[note][' + index + '][responsibility]">' + responsibility + '</textarea>' +
             '  <textarea class="observechange annotation" id="biblio_identifier_note_' + index + '_annotation" name="biblio_identifier[note][' + index + '][annotation]">' + annotation + '</textarea>' +
             '  <span class="delete" onclick="multiRemove(this.parentNode)" title="delete">x</span>' +
             '  <span class="move" title="move">o</span>' +
             '</li>';

  multiUpdate('note', item);
}

function multiAddShortTitleList(type)
{
  var title          = jQuery('#multiPlus_' + type + ' > input')[0].value;
  var responsibility = jQuery('#multiPlus_' + type + ' > select')[0].value;

  var index = multiGetNextIndex(type);

  var item = '<li>' +
             '  <input class="observechange title" id="biblio_identifier_' + type + '_' + index + '_title" name="biblio_identifier[' + type + '][' + index + '][title]" value="' + title + '" type="text">' +
             '  <select name="biblio_identifier[' + type + '][' + index + '][responsibility]" id="biblio_identifier_' + type + '_' + index + '_responsibility" class="observechange responsibility">' +
             '  <option value="BP"'        + (responsibility == 'BP'        ? ' selected="selected"' : '') + '>Bibliographie Papyrologique</option>' +
             '  <option value="Checklist"' + (responsibility == 'Checklist' ? ' selected="selected"' : '') + '>Checklist</option>' +
             '  </select>' +
             '  <span class="delete" onclick="multiRemove(this.parentNode)" title="delete">x</span>' +
             '  <span class="move" title="move">o</span>' +
             '</li>';

  multiUpdate(type, item);
}

function multiAddRelatedList(type)
{
  var pointer = jQuery('#multiPlus_' + type + ' > input')[0].value.replace(/\s+/, '');

  if(pointer.indexOf('http://papyri.info/biblio/') != 0){
    pointer = 'http://papyri.info/biblio/' +  pointer;
  }

  var index = multiGetNextIndex(type);

  var item = '<li>' +
             '  <input class="observechange pointer" id="biblio_identifier_' + type + '_' + index + '" name="biblio_identifier[' + type + '][' + index + ']" title="" value="' + pointer + '" type="text">' +
             '  <span class="delete" onclick="multiRemove(this.parentNode)" title="delete">x</span>' +
             '  <span class="move" title="move">o</span>' +
             '</li>';

  multiUpdate(type, item);
}

function multiAddNameList(type)
{
  var firstName = jQuery('#multiPlus_' + type + ' > input')[0].value;
  var lastName  = jQuery('#multiPlus_' + type + ' > input')[1].value;
  var name      = jQuery('#multiPlus_' + type + ' > input')[2].value;

  var index = multiGetNextIndex(type);

  var item = '<li>' + 
             '  <input type="text" value="' + firstName + '" name="biblio_identifier[' + type + '][' + index + '][firstName]" id="biblio_identifier_' + type + '_' + index + '_firstName" class="observechange firstName">' + 
             '  <input type="text" value="' + lastName + '" name="biblio_identifier[' + type + '][' + index + '][lastName]" id="biblio_identifier_' + type + '_' + index + '_lastName" class="observechange lastName">' + 
             '  <input type="text" value="' + name + '" name="biblio_identifier[' + type + '][' + index + '][name]" id="biblio_identifier_' + type + '_' + index + '_name" class="observechange name">' + 
             '  <span title="x" onclick="multiRemove(this.parentNode)" class="delete">x</span>' + 
             '  <span title="o" class="move">o</span>' + 
             '</li>';

  multiUpdate(type, item);
}

function multiAddPublisherList()
{
  var publisherType  = jQuery('#multiPlus_publisherList > select')[0].value;
  var value          = jQuery('#multiPlus_publisherList > input')[0].value;

  var index = multiGetNextIndex('publisherList');

  var item = '<li id="" style="position: relative;">' +
             '  <select name="biblio_identifier[publisherList][' + index + '][publisherType]" id="biblio_identifier_publisherList_' + index + '_publisherType" class="observechange publisherType">' +
             '  <option value="publisher"' + (publisherType == 'publisher' ? ' selected="selected"' : '') + '>Name</option>' +
             '  <option value="pubPlace"'  + (publisherType == 'pubPlace'  ? ' selected="selected"' : '') + '>Place</option>' +
             '  </select>' +
             '  <input type="text" value="' + value + '" name="biblio_identifier[publisherList][' + index + '][value]" id="biblio_identifier_publisherList_' + index + '_value" class="observechange value">' +
             '  <span title="x" onclick="multiRemove(this.parentNode)" class="delete">x</span>' +
             '  <span title="o" class="move">o</span>' +
             '</li>';

  multiUpdate('publisherList', item);
}

function multiAddRelatedArticleList()
{
  var series    = jQuery('#multiPlus_relatedArticleList > input')[0].value;
  var volume    = jQuery('#multiPlus_relatedArticleList > input')[1].value;
  var number    = jQuery('#multiPlus_relatedArticleList > input')[2].value;
  var ddb       = jQuery('#multiPlus_relatedArticleList > input')[3].value;
  var tm        = jQuery('#multiPlus_relatedArticleList > input')[4].value;
  var inventory = jQuery('#multiPlus_relatedArticleList > input')[5].value;

  var index = multiGetNextIndex('relatedArticleList');

  var item = '<li id="" style="position: relative;">' +
             '  <input type="text" value="' + series + '" name="biblio_identifier[relatedArticleList][' + index + '][series]" id="biblio_identifier_relatedArticleList_' + index + '_series" class="observechange series">' +
             '  <input type="text" value="' + volume + '" name="biblio_identifier[relatedArticleList][' + index + '][volume]" id="biblio_identifier_relatedArticleList_' + index + '_volume" class="observechange volume">' +
             '  <input type="text" value="' + number + '" name="biblio_identifier[relatedArticleList][' + index + '][number]" id="biblio_identifier_relatedArticleList_' + index + '_number" class="observechange number">' +
             '  <input type="text" value="' + ddb + '" name="biblio_identifier[relatedArticleList][' + index + '][ddb]" id="biblio_identifier_relatedArticleList_' + index + '_ddb" class="observechange ddb">' +
             '  <input type="text" value="' + tm + '" name="biblio_identifier[relatedArticleList][' + index + '][tm]" id="biblio_identifier_relatedArticleList_' + index + '_tm" class="observechange tm">' +
             '  <input type="text" value="' + inventory + '" name="biblio_identifier[relatedArticleList][' + index + '][inventory]" id="biblio_identifier_relatedArticleList_' + index + '_inventory" class="observechange inventory">' +
             '  <span title="x" onclick="multiRemove(this.parentNode)" class="delete">x</span>' +
             '  <span title="o" class="move">o</span>' +
             '</li>';

  multiUpdate('relatedArticleList', item);
}

/**** check ****/

function checkNotAddedMultiples(){
  if(jQuery('#authorList_firstName').value.match(/.+/) || jQuery('#authorList_lastName').value.match(/.+/) || jQuery('#authorList_name').value.match(/.+/)){
    multiAddNameList('authorList');
  }

  if(jQuery('#editorList_firstName').value.match(/.+/) || jQuery('#editorList_lastName').value.match(/.+/) || jQuery('#editorList_name').value.match(/.+/)){
    multiAddNameList('editorList');
  }

  if(jQuery('#journalTitleShort_title').value.match(/.+/)){
    multiAddShortTitleList('journalTitleShort');
  }

  if(jQuery('#bookTitleShort_title').value.match(/.+/)){
    multiAddShortTitleList('bookTitleShort');
  }

  if(jQuery('#papyrologicalSeriesTitleShort_title').value.match(/.+/)){
    multiAddShortTitleList('papyrologicalSeriesTitleShort');
  }

  if(jQuery('#note_responsibility').value.match(/.+/) && jQuery('#note_annotation').value.match(/.+/)){
    multiAddNote();
  }

  if(jQuery('#containerList_pointer').value.match(/.+/)){
    multiAddRelatedList('containerList');
  }

  if(jQuery('#revieweeList_pointer').value.match(/.+/)){
    multiAddRelatedList('revieweeList');
  }

  if(jQuery('#publisherList_publisherType').value.match(/.+/) && jQuery('#publisherList_value').value.match(/.+/)){
    multiAddPublisherList();
  }

  if(jQuery('#relatedArticleList_series').value.match(/.+/) || jQuery('#relatedArticleList_inventory').value.match(/.+/)){
    multiAddRelatedArticleList();
  }
}

Event.observe(window, 'load', function() {

  jQuery('.quickSave').bind('click', function(e){checkNotAddedMultiples(); rememberToggledView(); set_conf_false(); jQuery('form.edit_biblio_identifier')[0].submit();});});
  jQuery('#identifier_submit').bind('click', checkNotAddedMultiples);

});
