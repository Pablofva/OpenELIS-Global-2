package org.openelisglobal.sample.validator;

import java.util.Iterator;
import org.dom4j.Document;
import org.dom4j.DocumentException;
import org.dom4j.DocumentHelper;
import org.dom4j.Element;
import org.openelisglobal.common.util.validator.CustomDateValidator.DateRelation;
import org.openelisglobal.common.util.validator.GenericValidator;
import org.openelisglobal.common.validator.ValidationHelper;
import org.openelisglobal.sample.form.SamplePatientEntryForm;
import org.springframework.stereotype.Component;
import org.springframework.validation.Errors;
import org.springframework.validation.Validator;

@Component
public class SamplePatientEntryFormValidator implements Validator {

    @Override
    public boolean supports(Class<?> clazz) {
        return SamplePatientEntryForm.class.isAssignableFrom(clazz);
    }

    @Override
    public void validate(Object target, Errors errors) {
        SamplePatientEntryForm form = (SamplePatientEntryForm) target;

        // sampleXML
        if (!GenericValidator.isBlankOrNull(form.getSampleXML())) {
            validateSampleXML(form.getSampleXML(), errors);
        }
    }

    @SuppressWarnings("unchecked")
    private void validateSampleXML(String sampleXML, Errors errors) {
        try {
            Document sampleDom = DocumentHelper.parseText(sampleXML);
            for (Iterator<Element> iter = sampleDom.getRootElement().elementIterator("sample"); iter.hasNext();) {
                Element sampleItem = iter.next();
                validateSampleItem(sampleItem, errors);
                if (errors.hasErrors()) {
                    return;
                }
            }
        } catch (DocumentException e) {
            errors.reject("batchentry.error.sampleXML.invalid");
        }
    }

    private void validateSampleItem(Element sampleItem, Errors errors) {
        // Validación de IDs de pruebas
        String[] testIDs = sampleItem.attributeValue("tests").split(",");
        for (String testID : testIDs) {
            ValidationHelper.validateIdField(testID, "sampleXML", "sampleXML tests", errors, false); // false para opcional
            if (errors.hasErrors()) return;
        }

        // Validación de panel IDs
        String[] panelIDs = sampleItem.attributeValue("panels").split(",");
        for (String panelID : panelIDs) {
            ValidationHelper.validateIdField(panelID, "sampleXML", "sampleXML panels", errors, false); // false para opcional
            if (errors.hasErrors()) return;
        }

        // Validación de la fecha como opcional
        String collectionDate = sampleItem.attributeValue("date").trim();
        if (!GenericValidator.isBlankOrNull(collectionDate)) { // Solo validar si tiene valor
            ValidationHelper.validateDateField(collectionDate, "sampleXML", "sampleXML date", errors, DateRelation.PAST, false);
        }
        if (errors.hasErrors()) return;

        // Validación de la hora como opcional
        String collectionTime = sampleItem.attributeValue("time").trim();
        if (!GenericValidator.isBlankOrNull(collectionTime)) { // Solo validar si tiene valor
            ValidationHelper.validateTimeField(collectionTime, "sampleXML", "sampleXML time", errors, false);
        }
        if (errors.hasErrors()) return;

        // Validación del sampleID
        String sampleId = sampleItem.attributeValue("sampleID");
        ValidationHelper.validateIdField(sampleId, "sampleXML", "sampleXML sampleID", errors, false); // false para opcional
    }
}
