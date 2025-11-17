<script setup>
  import { ref } from "vue";
  import { invoke } from "@tauri-apps/api/tauri";

  const greetMsg = ref("");
  const name = ref("");

  async function greet() {
    // Learn more about Tauri commands at https://v1.tauri.app/v1/guides/features/command
    greetMsg.value = await invoke("greet", { name: name.value });
  }
</script>

<template>
   <iframe src="https://pocketoil.com/web"></iframe>
</template>

<style>
  #app {
    width: 100%;
    height: 100vh;
    overflow: hidden;
  }
  body {
    margin: 0;
  }
  iframe {
    width: 100%;
    height: 100%;
    border: none;
  }
</style>
