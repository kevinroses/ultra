<template lang="pug">
.supported-chains
  .alcor-inner
    SectionTitle.section-title Supported & Upcoming Chains
    .chains
      img.chain(src='~/assets/images/supportedchain-4.svg')
      img.chain(src='~/assets/images/supportedchain-1.svg')
      img.chain(src='~/assets/images/supportedchain-2.svg')
      img.chain(src='~/assets/images/supportedchain-3.svg')
      span.more and more...
</template>

<script>
import SectionTitle from '@/components/landing/SectionTitle'
import SSpacer from '@/components/SSpacer'
export default {
  name: 'SupportedChains',
  components: {
    SectionTitle,
    SSpacer
  },
  data: () => ({})
}
</script>

<style scoped lang="scss">
.supported-chains {
  background: linear-gradient(
    181.03deg,
    rgba(255, 255, 255, 0) -7.7%,
    rgba(57, 255, 136, 0.09) 50.74%,
    rgba(255, 255, 255, 0) 106.8%
  );
  padding: 20px 0;
  min-height: 300px;
}
.section-title {
  margin-bottom: 20px;
}
.chains {
  margin-bottom: 30px;
  display: flex;
  justify-content: space-between;
  flex-wrap: wrap;
}
.inner-container {
  padding: 40px 10px;
  background: rgba(33, 33, 33, 0.6);
  background: var(--hover);
  border-radius: 24px;
  display: flex;
  flex-direction: column;
  align-items: center;
  .title {
    font-size: 2rem;
    text-align: center;
  }
  .text {
    text-align: center;
    margin: 10px 0;
    margin-bottom: 40px;
    color: var(--text-grey-thirdly);
  }
  .social-items {
    display: flex;
    justify-content: center;
    flex-wrap: wrap;
    width: 100%;
    // max-width: 640px;
    .item {
      display: flex;
      flex-direction: column;
      align-items: center;
      transition: opacity 0.3s;
      padding: 8px 12px;
      &:hover {
        opacity: 0.8;
      }
      .icon {
        width: 60px;
        height: 60px;
        display: flex;
        align-items: center;
        justify-content: center;
        background: white;
        border-radius: 12px;
        img {
          width: 48px;
          height: 48px;
        }
      }
    }
    .name {
      margin: 8px 0;
      color: var(--text-default);
    }
    .desc {
      color: var(--text-grey-thirdly);
    }
  }
}

.chain {
  object-fit: contain;
}

@media only screen and (max-width: 1240px) {
  .chains {
    justify-content: center;
    align-items: center;
    .chain {
      margin: 12px;
    }
  }
}
</style>
