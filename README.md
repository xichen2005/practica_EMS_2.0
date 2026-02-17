# Pipeline-jenkins-java

Repositorio para el laboratorio de CI con Jenkins

## Descripción del laboratorio

En este laboratorio el alumno aprenderá los fundamentos de los pipelines de Jenkins y configurará un pipeline sencillo
para una aplicación Java con Spring Boot y Maven. Se conectará Github con Jenkins mediante *hooks* de forma que cada vez
que se realice un commit en el repositorio se ejecute de forma automática el pipeline de Jenkins.

[![License: CC BY-NC-SA 4.0](https://img.shields.io/badge/License-CC_BY--NC--SA_4.0-lightgrey.svg)](https://creativecommons.org/licenses/by-nc-sa/4.0/)

## Configuración del servidor de CI

En la cloudshell de Azure, subimos el fichero jenkins-init-java21.sh en la shell de Azure clickando en “Manage files” -> Upload

```SHELL
# creamos una carpeta nueva 
mkdir jenkins-get-started

# movemos el fichero a la carpeta
mv jenkins-init-java21.sh jenkins-get-started

# cambiamos de carpeta
cd jenkins-get-started

# creamos un nuevo grupo de recursos en azure
az group create --name jenkinsems2026-rg --location spaincentral

# creamos una máquina virtual
az vm create \
  --resource-group jenkinsems2026-rg \
  --name jenkinsems-vm-2026 \
  --image Ubuntu2204 \
  --admin-username jenkinsuser \
  --admin-password PASSWORD-12-32CARACTERES-MAY-MIN-NUMERO-CARACTERESESPECIALES \
  --generate-ssh-keys \
  --public-ip-sku Standard \
  --custom-data jenkins-init-java21.sh \
  --size Standard_B2s_v2

#abrimos el puerto 8080
az vm open-port --resource-group jenkinsems2026-rg --name jenkinsems-vm-2026 --port 8080 --priority 1010

# conexion por ssh, si nos pide confirmación de fingerprint decir que sí, e introducir la contraseña
ssh jenkinsuser@<ip>

# mostrar el contenido del fichero por pantalla
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

## Resolución de problemas con la suscripción de Estudiantes 

Las suscripciones de Estudiante de forma aleaotoria tienen limitaciones:
- Limitación del tipo de suscripción/cuotas o del proveedor del recurso (Microsoft.Compute). Para comprobar las localizaciones disponibles:
```SHELL
  az provider show -n Microsoft.Compute \
  --query "resourceTypes[?resourceType=='virtualMachines'].locations[]" -o tsv
```

- Si este comando lista localizaciones como la usada en el tutorial ("Spain Central") y aún así el comando falla, se debe a limitaciones en la localizaciones permitidas en tu suscripción según Azure Policy. Con el siguiente script vamos a listar
todas las regiones “Physical” disponibles en tu suscripción y marcar si están permitidas por Policy (si no se encuentra ninguna allowlist, asume todas permitidas por policy):

```SHELL
az policy assignment list  --subscription $(az account show --query id -o tsv)  --query "[?parameters.listOfAllowedLocations.value!=null].parameters.listOfAllowedLocations.value[]"  -o tsv
```

Una vez hemos determinado las localizaciones disponibles, podemos crear la MV indicando una de esas localizaciones permitidas, por ejemplo switzerlandnorth
```SHELL
az vm create \
  --resource-group jenkinsems2026-rg \
  --name jenkinsems-vm-2026 \
  --image Ubuntu2204 \
  --admin-username jenkinsuser \
  --admin-password PASSWORD-12-32CARACTERES-MAY-MIN-NUMERO-CARACTERESESPECIALES \
  --generate-ssh-keys \
  --public-ip-sku Standard \
  --custom-data jenkins-init-java21.sh \
  --size Standard_B2s_v2
  --location switzerlandnorth
```
## Resolución de problemas con el servidor Jenkins
Una vez estás conectado por ssh a la máquina donde has instalado Jenkins:

1. Comprobar si el servicio está instalado Jenkins normalmente se ejecuta como un servicio:
```SHELL
systemctl status jenkins
```
Si está instalado, verás información del servicio (active, running, stopped, etc.).
Si no está instalado, te dirá: Unit jenkins.service could not be found.

2. Buscar el paquete instalado
```SHELL
dpkg -l | grep jenkins
```
Si aparece una línea con jenkins, está instalado mediante dpkg/apt.
Si no aparece nada, probablemente no esté instalado por ese método.

3. Comprobar si existe el ejecutable

```SHELL
which jenkins
o
whereis jenkins
```
Si devuelve una ruta (por ejemplo /usr/bin/jenkins), está instalado.
Si no devuelve nada útil, no está instalado.

4. Comprobar si el puerto por defecto está activo
Jenkins suele ejecutarse en http://localhost:8080 Puedes verificar si algo está escuchando en ese puerto:
```SHELL
sudo lsof -i :8080
```
Si aparece un proceso llamado java o jenkins, entonces Jenkins está activo.

