import { ref, watch, type Ref } from 'vue';

export function useDebounce<T>(source: Ref<T>, delay: number = 300): Ref<T> {
  const debounced = ref(source.value) as Ref<T>;
  let timeout: any = null;

  watch(source, (newVal) => {
    clearTimeout(timeout);
    timeout = setTimeout(() => {
      debounced.value = newVal;
    }, delay);
  });

  return debounced;
}
