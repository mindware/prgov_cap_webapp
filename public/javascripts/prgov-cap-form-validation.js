
$(document).ready(function() {

  var fecha = new Date();
  fecha.setFullYear(new Date().getFullYear()-18);

  $('#birth_date input').datepicker({
    viewMode: "years",
    endDate : fecha
  });

  $('#certificado').bootstrapValidator({
    //live: 'disabled',
    message: 'Debe revisar el contenido de este campo.',
    //feedbackIcons: {
      //valid: 'glyphicon glyphicon-ok',
      //invalid: 'glyphicon glyphicon-remove',
      //validating: 'glyphicon glyphicon-refresh'
    //},
    fields: {
      nombre_nombre: {
        validators: {
          notEmpty: {
            message: 'Debe escribir su nombre'
          },
          stringLength: {
            max: 20,
            message: 'Debe limitar el contenido de este campo a 20 caracteres'
          }
        }
      },
      nombre_inicial: {
        validators: {
          stringLength: {
            max: 1,
            message: 'Debe limitar el contenido de este campo a 1 caracter'
          }
        }
      },
      nombre_paterno: {
        validators: {
          notEmpty: {
            message: 'Debe escribir su apellido paterno'
          },
          stringLength: {
            max: 20,
            message: 'Debe limitar el contenido de este campo a 20 caracteres'
          }
        }
      },
      nombre_materno: {
        validators: {
          stringLength: {
            max: 20,
            message: 'Debe limitar el contenido de este campo a 20 caracteres'
          }
        }
      },
      birth_date: {
        validators: {
          notEmpty: {
            message: 'Debe escribir su fecha de nacimiento'
          },
          date: {
            format: 'MM/DD/YYYY'
          }
        }
      },
      sex: {
        validators: {
          notEmpty: {
            message: 'Debe especificar su género'
          }
        }
      },
      ss_01: {
        validators: {
          notEmpty: {
            message: 'Debe escribir su número de seguro social.'
          },
          regexp: {
            regexp: /^[0-9]+-/,
            message: 'El formato para el seguro social es xxx-xx-xxxx, complete solo de números y guión.'
          },
          stringLength: {
            min: 11,
            max: 11,
            message: 'El formato para el seguro social es xxx-xx-xxxx'
          }
        }
      },
      licencia: {
        validators: {
          notEmpty: {
            message: 'Debe escribir su número de identificación provista por DTOP.'
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
      purpose: {
        validators: {
          notEmpty: {
            message: 'Debe especificar el propósito para el cual solicita el certificado'
          },
          stringLength: {
            min: 1,
            max: 2,
            message: 'Asegúrese de haber seleccionado una opción válida'
          }
        }
      },
      entrega_email: {
        validators: {
          notEmpty: {
            message: 'Debe escribir su correo electrónico'
          },
          emailAddress: {
            message: 'La información entrada no está en el formato correcto de un correo electrónico'
          },
          identical: {
            field: 'confirm_email',
            message: 'La información del correo electrónico no es la misma.'
          }
        }
      },
      confirm_email: {
        validators: {
          notEmpty: {
            message: 'Debe escribir nuevamente su correo electrónico'
          },
          emailAddress: {
            message: 'La información entrada no está en el formato correcto de un correo electrónico'
          },
          identical: {
            field: 'entrega_email',
            message: 'La información del correo electrónico no es la misma.'
          }
        }
      }
    }
  })

  .find('[name="telephone_number"]').mask('(000) 000-0000');
});
