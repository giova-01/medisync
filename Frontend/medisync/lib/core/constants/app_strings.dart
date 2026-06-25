abstract final class AppStrings {
  // App
  static const appName = 'MediSync';
  static const appTagline = 'Adherencia Terapéutica';

  // Auth actions
  static const login = 'Iniciar sesión';
  static const register = 'Registrarse';
  static const logout = 'Cerrar sesión';
  static const recoverPassword = 'Recuperar contraseña';
  static const sendRecoveryEmail = 'Enviar correo de recuperación';

  // Auth fields
  static const email = 'Correo electrónico';
  static const password = 'Contraseña';
  static const confirmPassword = 'Confirmar contraseña';
  static const nombre = 'Nombre';
  static const apellido = 'Apellido';

  // Auth links
  static const forgotPassword = '¿Olvidaste tu contraseña?';
  static const noAccount = '¿No tenés cuenta? ';
  static const hasAccount = '¿Ya tenés cuenta? ';

  // Profile selector
  static const selectProfile = 'Seleccioná tu perfil';
  static const selectProfileSubtitle = 'Este rol definirá lo que podés ver y hacer en la aplicación.';
  static const profilePaciente = 'Paciente';
  static const profileCuidador = 'Cuidador';
  static const profileProfesional = 'Profesional de Salud';
  static const profilePacienteDesc = 'Gestiono mi propia medicación y signos vitales.';
  static const profileCuidadorDesc = 'Supervisó el tratamiento de un familiar a mi cargo.';
  static const profileProfesionalDesc = 'Gestiono los esquemas de mis pacientes vinculados.';
  static const continueButton = 'Continuar';

  // Validation errors
  static const requiredField = 'Este campo es obligatorio';
  static const invalidEmail = 'Ingresá un correo electrónico válido';
  static const passwordTooShort = 'La contraseña debe tener al menos 8 caracteres';
  static const passwordRequirements =
      'Debe incluir mayúsculas, minúsculas, números y un carácter especial';
  static const passwordsDontMatch = 'Las contraseñas no coinciden';
  static const nameTooShort = 'Debe tener al menos 2 caracteres';
  static const mustSelectProfile = 'Seleccioná un perfil para continuar';

  // Network / server errors
  static const networkError = 'Sin conexión. Verificá tu internet e intentá nuevamente.';
  static const serverError = 'Error del servidor. Intentá de nuevo más tarde.';
  static const accountLocked =
      'Tu cuenta fue bloqueada 30 minutos por múltiples intentos fallidos.';
  static const invalidCredentials = 'Correo o contraseña incorrectos.';

  // Success messages
  static const recoveryEmailSent =
      'Te enviamos un correo para recuperar tu contraseña. Revisá tu bandeja de entrada.';

  // Home placeholder
  static const welcomeMessage = 'Bienvenido/a';

  // user_profile
  static const profile = 'Mi Perfil';
  static const editProfile = 'Editar Perfil';
  static const saveChanges = 'Guardar cambios';
  static const links = 'Vínculos';
  static const requestLink = 'Solicitar vinculación';
  static const targetEmail = 'Email del Paciente';
  static const vinculosPendientes = 'Solicitudes pendientes';
  static const vinculosActivos = 'Vínculos activos';
  static const accept = 'Aceptar';
  static const reject = 'Rechazar';
  static const revoke = 'Revocar';
  static const confirmRevoke = '¿Revocar el acceso de este usuario?';
  static const patologias = 'Patologías (separadas por coma)';
  static const fechaNacimiento = 'Fecha de nacimiento';
  static const parentesco = 'Parentesco con el paciente';
  static const matricula = 'Matrícula profesional';
  static const especialidad = 'Especialidad médica';
  static const cancel = 'Cancelar';
  static const confirmLogoutMessage = '¿Querés cerrar tu sesión actual?';

  // Navigation tabs
  static const tabTomas = 'Tomas';
  static const tabVitales = 'Vitales';
  static const tabAlertas = 'Alertas';
  static const tabPerfil = 'Perfil';
  static const tabPaciente = 'Paciente';
  static const tabVinculos = 'Vínculos';
  static const tabMedicacion = 'Medicación';
  static const tabVinculados = 'Vinculados';
  static const comingSoon = 'Próximamente';

  // medication
  static const myMedications = 'Mis Medicamentos';
  static const addMedication = 'Agregar medicamento';
  static const editMedication = 'Editar medicamento';
  static const deleteMedication = 'Eliminar medicamento';
  static const confirmDeleteMedication = '¿Eliminar este medicamento del esquema?';
  static const medicationName = 'Nombre del medicamento';
  static const medicationDose = 'Dosis (ej: 10mg)';
  static const medicationFrequency = 'Frecuencia (horas entre tomas)';
  static const medicationStartDate = 'Fecha de inicio';
  static const medicationEndDate = 'Fecha de fin (opcional)';
  static const dailyIntakes = 'Tomas del día';
  static const noIntakesToday = 'No hay tomas programadas para hoy';
  static const confirmIntake = 'Confirmar';
  static const postponeIntake = 'Posponer';
  static const intakeConfirmed = 'Toma confirmada';
  static const intakePostponed = 'Toma pospuesta';
  static const saveMedication = 'Guardar medicamento';
  static const medicationSaved = 'Medicamento guardado';
  static const medicationDeleted = 'Medicamento eliminado';
  static const patientView = 'Vista del Paciente';
  static const noLinkedPatient = 'No tenés un paciente vinculado activo.';
  static const frequencyLabel = 'Cada';
  static const frequencyHours = 'horas';

  // device
  static const deviceTitle = 'Dispositivo BLE';
  static const deviceDescription =
      'Buscá y conectá tu pulsera MediSync para registrar tus signos vitales automáticamente.';
  static const deviceConnected = 'Dispositivo conectado';
  static const deviceDisconnected = 'Sin dispositivo conectado';
  static const devicePrompt =
      'Conectá tu pulsera para ver tus datos de salud en tiempo real.';
  static const connectDevice = 'Conectar dispositivo';
  static const disconnectDevice = 'Desconectar';
  static const scanDevices = 'Buscar dispositivos';
  static const scanning = 'Buscando dispositivos...';
  static const connecting = 'Conectando...';
  static const deviceFound = 'Dispositivos encontrados';
  static const noDevicesFound =
      'No se encontraron dispositivos BLE. Asegurate de que tu pulsera esté encendida y cerca.';
  static const bleError =
      'Error de Bluetooth. Verificá que el Bluetooth esté activado.';
  static const deviceSignal = 'Señal';

  // alerts
  static const alerts = 'Alertas';
  static const markAllAsRead = 'Marcar todas como leídas';
  static const noAlerts = 'No tenés alertas por ahora.';
  static const alertMarkedRead = 'Alerta marcada como leída';
  static const justNow = 'Hace un momento';

  // vital_signs
  static const vitalSigns = 'Signos Vitales';
  static const heartRate = 'Frecuencia Cardíaca';
  static const oxygenSaturation = 'Saturación de Oxígeno';
  static const temperature = 'Temperatura';
  static const last24Hours = 'Últimas 24 horas';
  static const noHistoryData = 'No hay datos históricos disponibles.';
  static const connectionLost = 'Se perdió la conexión con el dispositivo.';
  static const liveUpdating = 'Actualizando en tiempo real';
}
