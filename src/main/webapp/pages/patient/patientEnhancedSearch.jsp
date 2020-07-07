<%@ page language="java" contentType="text/html; charset=UTF-8" %>
<%@ page import="org.openelisglobal.common.action.IActionConstants,
			     org.openelisglobal.common.formfields.FormFields,
			     org.openelisglobal.common.formfields.FormFields.Field,
			     org.openelisglobal.common.provider.validation.AccessionNumberValidatorFactory,
			     org.openelisglobal.common.provider.validation.IAccessionNumberValidator,
			     org.openelisglobal.common.util.ConfigurationProperties.Property,
			     org.openelisglobal.common.util.*, org.openelisglobal.internationalization.MessageUtil" %>
<%@ page isELIgnored="false" %>
<%@ taglib prefix="form" uri="http://www.springframework.org/tags/form"%>
<%@ taglib prefix="spring" uri="http://www.springframework.org/tags"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>

<%@ taglib prefix="ajax" uri="/tags/ajaxtags" %>

<%@ taglib uri="http://tiles.apache.org/tags-tiles" prefix="tiles"%>

<c:set var="formName" value="${form.formName}"/>
<c:set var="localDBOnly" value='<%=Boolean.toString(ConfigurationProperties.getInstance().getPropertyValueLowerCase(Property.UseExternalPatientInfo).equals("false"))%>'/>
<c:set var="patientEnhancedSearch" value="${form.patientSearch}"/>

<%!
	AccessionNumberValidatorFactory accessionNumberValidatorFactory = new AccessionNumberValidatorFactory();
 %>

 <%
	 boolean supportSTNumber = FormFields.getInstance().useField(Field.StNumber);
	 boolean supportMothersName = FormFields.getInstance().useField(Field.MothersName);
	 boolean supportSubjectNumber = FormFields.getInstance().useField(Field.SubjectNumber);
	 boolean supportNationalID = FormFields.getInstance().useField(Field.NationalID);
	 boolean supportLabNumber = FormFields.getInstance().useField(Field.SEARCH_PATIENT_WITH_LAB_NO);
  	
  	IAccessionNumberValidator accessionNumberValidator = accessionNumberValidatorFactory.getValidator();
 
 %>

<script type="text/javascript" src="scripts/ajaxCalls.js?" ></script>
<script type="text/javascript">

var supportSTNumber = <%= supportSTNumber %>;
var supportMothersName = <%= supportMothersName %>;
var supportSubjectNumber = <%= supportSubjectNumber %>;
var supportNationalID = <%= supportNationalID %>;
var supportLabNumber = <%= supportLabNumber %>;
var patientSelectID;
var patientInfoHash = [];
var patientChangeListeners = [];
var localDB = <c:out value="${localDBOnly}" />;
var newSearchInfo = false;

function searchPatients()
{
    var criteria = jQuery("#searchCriteria").val();
    var genders = jQuery("#genders").val();
    var value = jQuery("#searchValue").val();
    var splitName;
    var lastName = "";
    var firstName = "";
    var STNumber = "";
    var subjectNumber = "";
    var nationalID = "";
    var labNumber = "";


	newSearchInfo = false;
    jQuery("#resultsDiv").hide();
    jQuery("#searchLabNumber").val('');
    if( criteria == 1){
        firstName =  value.trim();
    }else if(criteria == 2){
        lastName = value.trim();
    }else if(criteria == 3){
        splitName = value.split(",");
        lastName = splitName[0].trim();
        firstName = splitName.size() == 2 ? splitName[1].trim() : "";
    }else if(criteria == 4){
        STNumber = value.trim();
        subjectNumber = value.trim();
        nationalID = value.trim();
    }else if(criteria == 5){
        labNumber = value;
        jQuery("#searchLabNumber").val(value);
    }
	patientSearch(lastName, firstName, STNumber, subjectNumber, nationalID, labNumber, "", false, processSearchSuccess);
}

function processSearchFailure(xhr)
{
	//alert( xhr.responseText );
	alert("<spring:message code="error.system"/>");
}

function processSearchSuccess(xhr)
{
	//alert( xhr.responseText );
	var formField = xhr.responseXML.getElementsByTagName("formfield").item(0);
	var message = xhr.responseXML.getElementsByTagName("message").item(0);
	var table = $("searchResultTable");

	clearTable(table);
	clearPatientInfoCache();

	if( message.firstChild.nodeValue == "valid" )
	{
		$("noPatientFound").hide();
		$("searchResultsDiv").show();

		var resultNodes = formField.getElementsByTagName("result");

		for( var i = 0; i < resultNodes.length; i++ )
		{
			addPatientToSearch( table, resultNodes.item(i) );
		}
		<c:if test="${patientEnhancedSearch.loadFromServerWithPatient}" >
		if( resultNodes.length == 1 ){
			handleSelectedPatient();
		}
		</c:if>
	}else
	{
		$("searchResultsDiv").hide();
		$("noPatientFound").show();
		selectPatient( null );
	}
}

function clearSearchResultTable() {
	var table = $("searchResultTable");
	clearTable(table);
	clearPatientInfoCache();
	
}

function clearTable(table){
	var rows = table.rows.length - 1;
	while( rows > 0 ){
		table.deleteRow( rows-- );
	}
}

function clearPatientInfoCache(){
	patientInfoHash = [];
}

function addPatientToSearch(table, result ){
	var patient = result.getElementsByTagName("patient")[0];

	var firstName = getValueFromXmlElement( patient, "first");
	var lastName = getValueFromXmlElement( patient, "last");
	var gender = getValueFromXmlElement( patient, "gender");
	var DOB = getValueFromXmlElement( patient, "dob");
	var stNumber = getValueFromXmlElement( patient, "ST");
	var subjectNumber = getValueFromXmlElement( patient, "subjectNumber");
	var nationalID = getValueFromXmlElement( patient, "nationalID");
	var mother = getValueFromXmlElement( patient, "mother");
	var pk = getValueFromXmlElement( result, "id");
	var dataSourceName = getValueFromXmlElement( result, "dataSourceName");

	var row = createRow( table, firstName, lastName, gender, DOB, stNumber, subjectNumber, nationalID, mother, pk, dataSourceName );
	addToPatientInfo( firstName, lastName, gender, DOB, stNumber, subjectNumber, nationalID, mother, pk );

	if( row == 1 ){
		patientSelectID = pk;
		$("sel_1").checked = "true";
		selectPatient( pk );
	}
}

function getValueFromXmlElement( parent, tag ){
	var element = parent.getElementsByTagName( tag ).item(0);

	return element ? element.firstChild.nodeValue : "";
}

function createRow(table, firstName, lastName, gender, DOB, stNumber, subjectNumber, nationalID, mother, pk,  dataSourceName){

		var row = table.rows.length;

		var newRow = table.insertRow(row);

		newRow.id = "_" + row;

		var cellCounter = -1;

		var selectionCell = newRow.insertCell(++cellCounter);
		if( !localDB){
			var dataSourceCell = newRow.insertCell(++cellCounter);
			dataSourceCell.innerHTML = nonNullString( dataSourceName );
		}
		var lastNameCell = newRow.insertCell(++cellCounter);
		var firstNameCell = newRow.insertCell(++cellCounter);
		var genderCell = newRow.insertCell(++cellCounter);
		var dobCell = newRow.insertCell(++cellCounter);
		var motherCell = supportMothersName ? newRow.insertCell(++cellCounter) : null;
		var stCell = supportSTNumber ? newRow.insertCell(++cellCounter) : null;
		var subjectNumberCell = supportSubjectNumber ? newRow.insertCell(++cellCounter) : null;
		var nationalCell = supportNationalID ? newRow.insertCell(++cellCounter) : null;
		selectionCell.innerHTML = getSelectionHtml( row, pk );
		lastNameCell.innerHTML = nonNullString( lastName );
		firstNameCell.innerHTML = nonNullString( firstName );
		genderCell.innerHTML = nonNullString( gender );
		if( supportSTNumber){stCell.innerHTML = nonNullString( stNumber );}
		if( supportSubjectNumber){subjectNumberCell.innerHTML = nonNullString( subjectNumber );}
		if( supportNationalID){nationalCell.innerHTML = nonNullString( nationalID );}

		dobCell.innerHTML = nonNullString( DOB );
		if(supportMothersName){motherCell.innerHTML = nonNullString( mother );}

		return row;
}

function getSelectionHtml( row, key){
	return "<input name='selPatient' id='sel_" + row + "' value='" + key + "' onclick='selectPatient(this.value)' type='radio'>";
}

function /*String*/ nonNullString( target ){
	return target == "null" ? "" : target;
}

function addToPatientInfo( firstName, lastName, gender, DOB, stNumber, subjectNumber, nationalID, mother, pk ){
	var info = [];
	info["first"] = nonNullString( firstName );
	info["last"] = nonNullString( lastName );
	info["gender"] = nonNullString( gender );
	info["DOB"] = nonNullString( DOB );
	info["ST"] = nonNullString( stNumber );
	info["subjectNumber"] = nonNullString( subjectNumber );
	info["national"] = nonNullString( nationalID );
	info["mother"] = nonNullString( mother );

	patientInfoHash[pk] = info;
}


function selectPatient( patientID ){
    var i;
	if( patientID ){
		patientSelectID = patientID;

		var info = patientInfoHash[patientID];

		for(i = 0; i < patientChangeListeners.length; i++){
			patientChangeListeners[i](info["first"],info["last"],info["gender"],info["DOB"],info["ST"],info["subjectNumber"],info["national"],info["mother"], patientID);
		}

	}else{
		for(i = 0; i < patientChangeListeners.length; i++){
			patientChangeListeners[i]("","","","","","","","", null);
		}
	}
}

function /*void*/ addPatientChangedListener( listener ){
	patientChangeListeners.push( listener );
}


function /*void*/ handleEnterEvent( ){
		
		if( newSearchInfo ){
			searchPatients();
		}
		return false;
}

function /*void*/ dirtySearchInfo(e){ 
	var code = e ? e.which : window.event.keyCode;
	if( code != 13 ){
		newSearchInfo = true; 
	}
}
function /*void*/ doNothing(){ 
	
}

function checkIndex(select) {
	var indexVal = select.options[select.selectedIndex].value;
    var valueElem = jQuery("#searchValue");
	if (indexVal == "5") {
		jQuery("#scanInstruction").show();
        valueElem.attr("maxlength","<%= Integer.toString(accessionNumberValidator.getMaxAccessionLength()) %>");
	} else {
		jQuery("#scanInstruction").hide();
        valueElem.attr("maxlength","120");
	}
}

function enableSearchButton(eventCode){
    var valueElem = jQuery("#searchValue");
    var criteriaElem  = jQuery('#searchCriteria');
    var gendersElem  = jQuery('#genders');
    var searchButton = jQuery("#searchButton");
    if( valueElem.val() && criteriaElem.val() != "0" && criteriaElem.val() != "5"){
        searchButton.removeAttr("disabled");
        if( eventCode == 13 ){
            searchButton.click();
        }
    }else if(criteriaElem.val() == "5"){
    	if (valueElem.val().length >= <%= Integer.toString(accessionNumberValidator.getMinAccessionLength()) %>) {
        	searchButton.removeAttr("disabled");
            if( eventCode == 13 ){
                searchButton.click();
            }
    	} else {
            searchButton.attr("disabled", "disabled");
    	}
    }else{
        searchButton.attr("disabled", "disabled");
    }
}

function enableEnhancedSearchButton(eventCode){
	var enhancedSearchButton = jQuery("#enhancedSearchButton");
	enhancedSearchButton.removeAttr("disabled");
}

function handleSelectedPatient(){
    var accessionNumber = "";
    if(jQuery("#searchCriteria").val() == 5){//lab number
        accessionNumber = jQuery("#searchValue").val();
    }

    $("searchResultsDiv").style.display = "none";
   /*  var form = document.getElementById("mainForm");
    form.method = "get";
    form.action = '${form.formAction}'.sub('Form','') + "?accessionNumber=" + accessionNumber + "&patientID=" + patientSelectID;
    if( !(typeof requestType === 'undefined') ){
        form.action += "&type=" + requestType;
    }
    form.submit(); */
    var searchUrl = '${form.formAction}'.sub('Form','') + "?accessionNumber=" + accessionNumber + "&patientID=" + patientSelectID;
    if( !(typeof requestType === 'undefined') ){
    	searchUrl += "&type=" + requestType;
    }
    window.onbeforeunload = null;
    window.location = searchUrl;
}
</script>

<input type="hidden" id="searchLabNumber">

<div id="PatientPage" class="colorFill patientEnhancedSearch" style="display:inline;" >

	<h2><spring:message code="sample.entry.search"/></h2>
    <c:if test="${form.warning}">
        <h3 class="important-text"><spring:message code="order.modify.search.warning" /></h3>
    </c:if>
    <select id="searchCriteria"  style="float:left" onchange="checkIndex(this)" tabindex="1" class="patientEnhancedSearch">
    <c:forEach var="pair" items="${patientEnhancedSearch.searchCriteria}">
    	<option value="${pair.id}"> ${pair.value} </option>
    </c:forEach>
    </select>

    <input size="35"
           maxlength="120"
           id="searchValue"
           class="text patientEnhancedSearch"
           placeholder='<%=MessageUtil.getMessage("label.select.search.here")%>'
           type="text"
           oninput="enableSearchButton(event.which);"
           tabindex="2"/>

    <input type="button"
           name="searchButton"
           class="patientEnhancedSearch"
           value="<%= MessageUtil.getMessage("label.patient.search")%>"
           id="searchButton"
           onclick="searchPatients()"
           disabled="disabled" >
</div>

<div id="PatientPage" class="patientEnhancedSearch"
	style="text-align: left;">
	<h2><spring:message code="sample.entry.search" /></h2>
	<table>
		<tr>
			<td style="text-align: left;"><spring:message
					code="patient.subject.number" /> :</td>
			<td><form:input path="patientProperties.subjectNumber"
					id="subjectNumberSearchValue" size="40" oninput="enableEnhancedSearchButton(event.which);"
					placeholder='<%=MessageUtil.getMessage("label.select.search.here")%>' />
			</td>
		</tr>
		<tr>
			<td style="text-align: left;"><spring:message
					code="patient.epiLastName" /> :</td>
			<td><form:input path="patientProperties.lastName"
					id="lastNameSearchValue" onchange="updatePatientEditStatus();" size="40" oninput="enableSearchButton(event.which);"
					placeholder='<%=MessageUtil.getMessage("label.select.search.here")%>' />
			</td>
		</tr>
		<tr>
			<td style="text-align: left;"><spring:message
					code="patient.epiFirstName" /> :</td>
			<td><form:input path="patientProperties.firstName"
					id="firstNameSearchValue" onchange="updatePatientEditStatus();" size="40" oninput="enableSearchButton(event.which);"
					placeholder='<%=MessageUtil.getMessage("label.select.search.here")%>' />
			</td>
		</tr>
		</table>
		
		<table>
		<tr>
		<td style="text-align:right;">
			<spring:message code="patient.birthDate" />&nbsp;<%=DateUtil.getDateUserPrompt()%>:
		</td>
		<td>
            <form:input path="patientProperties.birthDateForDisplay" 
                      onkeyup="addDateSlashes(this,event); normalizeDateFormat(this);"
                      onchange="checkValidAgeDate( this ); updatePatientEditStatus();"
                      oninput="enableSearchButton(event.which);"
                      id="dateOfBirthSearchValue"
                      placeholder='<%=MessageUtil.getMessage("label.select.search.here")%>' 
                      cssClass="text"
					  size="20"
                      maxlength="10"/>
                      
			<div id="patientProperties.birthDateForDisplayMessage" class="blank" style="text-align: left;">
		</td>
		<td style="text-align:left;">
			<spring:message code="patient.age" />:
		</td>
		<td >
            <%-- <html:text property="patientProperties.age"
                       name="${form.formName}"
                       size="3"
                       maxlength="3"
                       onchange="handleAgeChange( this ); updatePatientEditStatus();"
                       styleClass="text"
                    id="age"/> --%>
           <form:input path="patientProperties.age" 
           			  onchange="handleAgeChange( this ); updatePatientEditStatus();"
           			  id="age"
                      cssClass="text"
                      size="3"
                      maxlength="3"
                        />
		</td>
			<td style="text-align: left;"><spring:message
					code="patient.gender" />:</td>
			<td><select id="searchGenders" style="float: left"
				onchange="checkIndex(this)" tabindex="1"
				class="patientEnhancedSearch">
				<option value=" " ></option>
					<c:forEach var="pair" items="${patientEnhancedSearch.genders}">
						<option value="${pair.id}">${pair.value}</option>
					</c:forEach>
			</select></td>
			<td><input type="button" name="enhanedSearchButton"
				class="patientEnhancedSearch"
				value="<%=MessageUtil.getMessage("label.patient.search")%>"
				id="enhancedSearchButton" onclick="searchPatients()" disabled="disabled">
			</td>
		</tr>
	</table>
</div>

<span id="scanInstruction" style="display: none;"><spring:message code="sample.search.scanner.instructions"/> </span>

	<div id="noPatientFound" align="center" style="display: none" >
		<h1><spring:message code="patient.search.not.found"/></h1>
	</div>
	<div id="searchResultsDiv" class="colorFill" style="display: none;" >
	<c:choose>
		<c:when test="${!localDBOnly}"  >
		<table id="searchResultTable" style="width:90%">
			<tr>
				<th width="2%"></th>
				<th width="10%" >
					<spring:message code="patient.data.source" />
				</th>
		</c:when>
		<c:otherwise>
		<table id="searchResultTable" width="70%">
			<tr>
				<th width="2%"></th>
		</c:otherwise>
	</c:choose>
				<th width="18%">
					<spring:message code="patient.epiLastName"/>
				</th>
				<th width="15%">
					<spring:message code="patient.epiFirstName"/>
				</th>
				<th width="5%">
					<spring:message code="patient.gender"/>
				</th>
				<th width="11%">
					<spring:message code="patient.birthDate"/>
				</th>
				<% if( supportMothersName ){ %>
				<th width="20%">
					<spring:message code="patient.mother.name"/>
				</th>
				<% } if(supportSTNumber){ %>
				<th width="12%">
					<spring:message code="patient.ST.number"/>
				</th>
				<% } %>
				<% if(supportSubjectNumber){ %>
				<th width="12%">
					<spring:message code="patient.subject.number"/>
				</th>
				<% } %>
				<% if(supportNationalID){ %>
				<th width="12%">
                    <%=MessageUtil.getContextualMessage("patient.NationalID") %>
                </th>
                <% } %>
			</tr>
		</table>
		<br/>
		 <c:if test="${!empty patientEnhancedSearch.selectedPatientActionButtonText}">
            <input type="button"
                   value="${patientEnhancedSearch.selectedPatientActionButtonText}"
                   id="selectPatientButtonID"
                   onclick="handleSelectedPatient()" />
        </c:if> 
		</div>
	</div>

