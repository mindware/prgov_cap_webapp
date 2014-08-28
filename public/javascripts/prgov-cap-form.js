
$(document).ready(function() {
  $('#birthdate-datetimepicker').datetimepicker({
    pickTime: false
  });

  $('#certificado').bootstrapValidator({
    /*
      feedbackIcons: {
      valid: 'glyphicon glyphicon-ok',
      invalid: 'glyphicon glyphicon-remove',
      validating: 'glyphicon glyphicon-refresh'
    },
    */
    fields: {
      name: {
        validators: {
          notEmpty: {
            message: 'Debe escribir su nombre'
          },
          stringLength: {
            max: 50,
            message: 'Debe limitar el contenido de este campo a 50 caracteres'
          }
        }
      },
      name_initial: {
        validators: {
          stringLength: {
            max: 1,
            message: 'Debe limitar el contenido de este campo a 1 caracter'
          }
        }
      },
      name_lastname_first: {
        validators: {
          notEmpty: {
            message: 'Debe escribir su apellido paterno'
          },
          stringLength: {
            max: 50,
            message: 'Debe limitar el contenido de este campo a 50 caracteres'
          }
        }
      },
      name_lastname_second: {
        validators: {
          stringLength: {
            max: 50,
            message: 'Debe limitar el contenido de este campo a 50 caracteres'
          }
        }
      },
      birthdate: {
        validators: {
          notEmpty: {
            message: 'Debe escribir su fecha de nacimiento'
          },
          date: {
            format: 'MM/DD/YYYY',
            message: 'El contenido no es una fecha valida'
          }
        }
      },
      id_dtop: {
        validators: {
          notEmpty: {
            message: 'Debe escribir su número de identificación'
          },
          digits: {
            message: 'En este espacio debe escribir solo números'
          },
          stringLength: {
            min: 7,
            max: 7,
            message: 'El número debe ser de 7 dígitos'
          }
        }
      },
      delivery_email: {
        validators: {
          notEmpty: {
            message: 'Debe escribir su correo electrónico'
          },
          emailAddress: {
            message: 'La información entrada no está en el formato correcto de un correo electrónico'
          }
        }
      },
      delivery_email_confirmation: {
        validators: {
          notEmpty: {
            message: 'Debe escribir nuevamente su correo electrónico'
          },
          emailAddress: {
            message: 'La información entrada no está en el formato correcto de un correo electrónico'
          },
          identical: {
            field: 'delivery_email',
            message: 'La información del correo electrónico no es la misma'
          }
        }
      }
    }
  });
});
