document.getElementById("ano").innerText = new Date().getFullYear();

const btn = document.getElementById("btn");
const hora = document.getElementById("hora");

btn.addEventListener("click", () => {
  if (hora.innerText) {
    hora.innerText = "";
    btn.innerText = "Mostrar horário local";
  } else {
    const horaAtual = new Date().toLocaleString();
    hora.innerText = `Agora são: ${horaAtual}`;
    btn.innerText = "Esconder horário";
  }
});
