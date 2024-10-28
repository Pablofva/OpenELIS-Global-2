import * as Yup from "yup";
import CreatePatientValidationSchema from "./CreatePatientValidationShema";

const OrderEntryValidationSchema = Yup.object().shape({
  sampleXML: Yup.string().required("La muestra es requerida"),
  patientProperties: CreatePatientValidationSchema,
  sampleOrderItems: Yup.object()
    .shape({
      labNo: Yup.string().required("Numero de laboratorio es requerido"),
      referringSiteName: Yup.string(),
      referringSiteId: Yup.string(),
      providerLastName: Yup.string(),
      providerFirstName: Yup.string(),
      providerEmail: Yup.string().email("Email Invalido"),
    })
});

export default OrderEntryValidationSchema;
