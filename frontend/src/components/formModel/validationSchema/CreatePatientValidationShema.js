import * as Yup from "yup";

const CreatePatientValidationSchema = Yup.object().shape({
  nationalId: Yup.string().required("Se requiere Dni"),
  birthDateForDisplay: Yup.string().required("Se requiere Fecha de Nacimiento")
    .test("valid-date", "Invalid date format", function (value) {
      const dateFormat = /^\d{2}\/\d{2}\/\d{4}$/;
      if (!value || !value.match(dateFormat)) {
        return false;
      }
      const [day, month, year] = value.split("/");
      const date = new Date(`${year}-${month}-${day}`);
      const date2 = new Date(`${year}-${day}-${month}`);

      const validDate1 = date instanceof Date && !isNaN(date);
      const validDate2 = date2 instanceof Date && !isNaN(date2);

      return validDate1 || validDate2;
    }),
  patientContact: Yup.object().shape({
    person: Yup.object().shape({
      email: Yup.string().email("Email de contacto debe ser valido"),
    }),
  }),
  gender: Yup.string().required("Genero es requerido"),
});

export default CreatePatientValidationSchema;
