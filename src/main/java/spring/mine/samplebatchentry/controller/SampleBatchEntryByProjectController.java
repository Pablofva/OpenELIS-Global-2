package spring.mine.samplebatchentry.controller;

import java.lang.reflect.InvocationTargetException;

import javax.servlet.http.HttpServletRequest;

import org.apache.commons.beanutils.PropertyUtils;
import org.jfree.util.Log;
import org.springframework.stereotype.Controller;
import org.springframework.validation.Errors;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.servlet.ModelAndView;
import spring.mine.common.controller.BaseController;
import spring.mine.common.form.BaseForm;
import spring.mine.common.validator.BaseErrors;
import spring.mine.sample.controller.BaseSampleEntryController;
import spring.mine.samplebatchentry.form.SampleBatchEntryForm;
import us.mn.state.health.lims.common.action.BaseActionForm;
import us.mn.state.health.lims.common.exception.LIMSRuntimeException;
import us.mn.state.health.lims.common.util.StringUtil;
import us.mn.state.health.lims.dictionary.ObservationHistoryList;
import us.mn.state.health.lims.organization.util.OrganizationTypeList;
import us.mn.state.health.lims.patient.valueholder.ObservationData;
import us.mn.state.health.lims.sample.form.ProjectData;

@Controller
public class SampleBatchEntryByProjectController extends BaseSampleEntryController {

	private static final String ON_DEMAND = "ondemand";
	private static final String PRE_PRINTED = "preprinted";

	@RequestMapping(value = "/SampleBatchEntryByProject", method = RequestMethod.POST)
	public ModelAndView showSampleBatchEntryByProject(HttpServletRequest request,
			@ModelAttribute("form") SampleBatchEntryForm form) {
		String forward = FWD_SUCCESS;
		if (form == null) {
			form = new SampleBatchEntryForm();
		}
		form.setFormAction("");
		BaseErrors errors = new BaseErrors();
		if (form.getErrors() != null) {
			errors = (BaseErrors) form.getErrors();
		}
		ModelAndView mv = checkUserAndSetup(form, errors, request);
		if (errors.hasErrors()) {
			return mv;
		}

		String study = request.getParameter("study");
		try {
			if ("viralLoad".equals(study)) {
				setupViralLoad(form, request);
			} else if ("EID".equals(study)) {
				setupEID(form, request);
			}
			setupCommonFields(form, request);
			forward = setForward(form);
		} catch (Exception e) {
			Log.error(e.toString());
			e.printStackTrace();
			forward = FWD_FAIL;
		}

		return findForward(forward, form);
	}

	private void setupEID(SampleBatchEntryForm form, HttpServletRequest request)
			throws IllegalAccessException, InvocationTargetException, NoSuchMethodException {
		ProjectData projectData = form.getProjectDataEID();
		PropertyUtils.setProperty(form, "programCode", StringUtil.getMessageForKey("sample.entry.project.LDBS"));
		String sampleTypes = "";
		String tests = "";
		if (projectData.getDryTubeTaken()) {
			sampleTypes = sampleTypes + StringUtil.getMessageForKey("sample.entry.project.ARV.dryTubeTaken");
		}
		if (projectData.getDbsTaken()) {
			sampleTypes = sampleTypes + " " + StringUtil.getMessageForKey("sample.entry.project.title.dryBloodSpot");
		}

		if (projectData.getDnaPCR()) {
			tests = tests + StringUtil.getMessageForKey("sample.entry.project.dnaPCR");
		}
		request.setAttribute("sampleType", sampleTypes);
		request.setAttribute("testNames", tests);
		PropertyUtils.setProperty(form, "projectData", projectData);
		ObservationData observations = new ObservationData();
		observations.setProjectFormName("EID_Id");
		PropertyUtils.setProperty(form, "observations", observations);
	}

	private void setupViralLoad(SampleBatchEntryForm form, HttpServletRequest request)
			throws IllegalAccessException, InvocationTargetException, NoSuchMethodException {
		ProjectData projectData = form.getProjectDataVL();
		PropertyUtils.setProperty(form, "programCode", StringUtil.getMessageForKey("sample.entry.project.LART"));
		String sampleTypes = "";
		String tests = "";
		if (projectData.getDryTubeTaken()) {
			sampleTypes = sampleTypes + StringUtil.getMessageForKey("sample.entry.project.ARV.dryTubeTaken");
		}
		if (projectData.getEdtaTubeTaken()) {
			sampleTypes = sampleTypes + " " + StringUtil.getMessageForKey("sample.entry.project.ARV.edtaTubeTaken");
		}

		if (projectData.getViralLoadTest()) {
			tests = tests + StringUtil.getMessageForKey("sample.entry.project.ARV.viralLoadTest");
		}
		request.setAttribute("sampleType", sampleTypes);
		request.setAttribute("testNames", tests);
		PropertyUtils.setProperty(form, "projectData", projectData);
		ObservationData observations = new ObservationData();
		observations.setProjectFormName("VL_Id");
		PropertyUtils.setProperty(form, "observations", observations);
	}

	private void setupCommonFields(SampleBatchEntryForm form, HttpServletRequest request)
			throws LIMSRuntimeException, IllegalAccessException, InvocationTargetException, NoSuchMethodException {
		PropertyUtils.setProperty(form, "currentDate", request.getParameter("currentDate"));
		PropertyUtils.setProperty(form, "currentTime", request.getParameter("currentTime"));
		PropertyUtils.setProperty(form, "receivedDateForDisplay",
				request.getParameter("sampleOrderItem.receivedDateForDisplay"));
		PropertyUtils.setProperty(form, "receivedTimeForDisplay", request.getParameter("sampleOrderItem.receivedTime"));
		addOrganizationLists(form);
	}

	protected void addOrganizationLists(SampleBatchEntryForm form)
			throws LIMSRuntimeException, IllegalAccessException, InvocationTargetException, NoSuchMethodException {

		// Get ARV Centers
		PropertyUtils.setProperty(form, "projectData.ARVCenters", OrganizationTypeList.ARV_ORGS.getList());
		PropertyUtils.setProperty(form, "organizationTypeLists", OrganizationTypeList.MAP);

		// Get EID Sites
		PropertyUtils.setProperty(form, "projectData.EIDSites", OrganizationTypeList.EID_ORGS.getList());
		PropertyUtils.setProperty(form, "projectData.EIDSitesByName", OrganizationTypeList.EID_ORGS_BY_NAME.getList());

		// Get EID whichPCR List
		// PropertyUtils.setProperty(form, "projectData.eidWhichPCRList",
		// ObservationHistoryList.EID_WHICH_PCR.getList());

		// Get EID secondTestReason List
		PropertyUtils.setProperty(form, "projectData.eidSecondPCRReasonList",
				ObservationHistoryList.EID_SECOND_PCR_REASON.getList());

		// Get SPE Request Reasons
		PropertyUtils.setProperty(form, "projectData.requestReasons",
				ObservationHistoryList.SPECIAL_REQUEST_REASONS.getList());

		PropertyUtils.setProperty(form, "projectData.isUnderInvestigationList",
				ObservationHistoryList.YES_NO.getList());
	}

	private String setForward(SampleBatchEntryForm form) {
		String method = form.getMethod();
		if (method == null) {
			Errors errors = new BaseErrors();
			errors.reject("", "null method of entry");
			saveErrors(errors);
			return FWD_FAIL;
		} else if (method.contains("On") && method.contains("Demand")) {
			return ON_DEMAND;
		} else if (method.contains("Pre") && method.contains("Printed")) {
			return PRE_PRINTED;
		} else {
			Errors errors = new BaseErrors();
			errors.reject("", "method of entry must be On Demand or Pre-Printed");
			saveErrors(errors);
			return FWD_FAIL;
		}
	}

	protected ModelAndView findLocalForward(String forward, BaseForm form) {
		if (ON_DEMAND.equals(forward)) {
			return new ModelAndView("sampleStudyBatchEntryOnDemandDefinition", "form", form);
		} else if (PRE_PRINTED.equals(forward)) {
			return new ModelAndView("sampleStudyBatchEntryPrePrintedDefinition", "form", form);
		} else if ("fail".equals(forward)) {
			return new ModelAndView("sampleBatchEntrySetupDefinition", "form", form);
		} else {
			return new ModelAndView("PageNotFound");
		}
	}

	@Override
	protected String getPageTitleKey() {
		return "sample.batchentry.title";
	}

	@Override
	protected String getPageSubtitleKey() {
		return "sample.batchentry.title";
	}
}