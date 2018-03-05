<style>
    @media (min-width: 1400px) {
      .container {
        width: 1380px;
      }
    }
</style>

<template>
  <div>
    <!-- <div class='container'> -->
        <compare-single :inputCode='globalCode'
                        :inputSettings='globalSettings'
                        >
        </compare-single>
      <!-- </div> -->
    </div>
</template>

<script lang='coffee' src="./compare-main.coffee"></script>
